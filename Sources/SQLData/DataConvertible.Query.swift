//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 12/31/19.
//

import Foundation

public extension SQLDataConvertible {
    
    func insert (on connectable: SQLConnectable, includeReferences: Bool, completion: @escaping (Error?) -> Void) {
        let queries = self.insertQueries(includeReferences: includeReferences)
        connectable.query(unorderedQueries: queries, completion: completion)
    }
    
    static func columnsToSelect () -> String {
        return columnsToSelect(keyPaths: dataKeyPaths)
    }
    static func columnsToSelect (keyPaths: [SQLData.KeyPathDataColumn]) -> String {
        
        return keyPaths.flatMap { keyPath in
            return keyPath.items.map({ "\(tableName).'\($0.column.name)'" })
        }.joined(separator: ", ")
    }
    
    static func selectMainTableQuery (where whereClause: String) -> String {
        return selectMainTableQuery(keyPaths: dataKeyPaths, where: whereClause)
    }
    static func selectMainTableQuery (keyPaths: [SQLData.KeyPathDataColumn], where whereClause: String) -> String {
        return "SELECT \(columnsToSelect(keyPaths: keyPaths)) FROM \(tableName) \(whereClause.isEmpty ? "" : " WHERE \(whereClause)")"
    }
    
    static func initializeStructure (on connectable: SQLConnectable, completion: @escaping (Error?) -> Void) {
        let queries = structureDescription().map({$0.query})
        connectable.query(unorderedQueries: queries, completion: completion)
    }
    static func select <T: SQLDataConvertible> (_ keyPath: WritableKeyPath<Self, T>, where whereClause: String, on connectable: SQLConnectable, row callback: @escaping (T) -> Void, completion: @escaping (Error?) -> Void) {
        
        if let keyPath = dataKeyPaths.first(where: { $0.keyPath == keyPath }) {
            T.select(selectMainTableQuery(keyPaths: [keyPath], where: whereClause), on: connectable, row: callback, completion: completion)
        } else {
            completion(nil)
        }
        
    }
    static func select (where whereClause: String, on connectable: SQLConnectable, row callback: @escaping (Self) -> Void, completion: @escaping (Error?) -> Void ) {
        select(selectMainTableQuery(where: whereClause), on: connectable, row: callback, completion: completion)
    }
    static func select (_ q: String, on connectable: SQLConnectable, row callback: @escaping (Self) -> Void, completion: @escaping (Error?) -> Void ) {

        let errorInSubPath = AtomicMutablePointer<Error?>(nil)
        
        let dispatchGroup = DispatchGroup()
        
        if connectable.isConcurrencyCapable {
            
            connectable.query(q, row: { (row) in
                loadFromRow(row: row, rowGroup: dispatchGroup, connectable: connectable, errorInSubPath: errorInSubPath, row: callback, completion: completion)
            }) { error in
                if let error = error {
                    completion(error)
                    return
                }
                
                dispatchGroup.notify(queue: connectable.defaultDispatchQueue) { completion(errorInSubPath.syncPointee) }
            }
            
        } else {
            
            connectable.query(q) { (table, error) in
                if let error = error {
                    completion(error)
                    return
                }
                
                for i in table.indices {
                    loadFromRow(row: table[i], rowGroup: dispatchGroup, connectable: connectable, errorInSubPath: errorInSubPath, row: callback, completion: completion)
                }
                
                dispatchGroup.notify(queue: connectable.defaultDispatchQueue) { completion(errorInSubPath.syncPointee) }
            }
            
        }
    }
    fileprivate static func loadFromRow (row: [String?], rowGroup: DispatchGroup, connectable: SQLConnectable, errorInSubPath: AtomicMutablePointer<Error?>, row callback: @escaping (Self) -> Void, completion: @escaping (Error?) -> Void ) {
        
        if errorInSubPath.syncPointee != nil {
            return
        }
        
        rowGroup.enter()
        
        var item = Self()
        item.read(mainRow: row)
        
        let subDispatchGroup = DispatchGroup()
        
        let completionBlock = { (error: Error?) in
            subDispatchGroup.leave()
            
            if let error = error, errorInSubPath.syncPointee == nil {
                errorInSubPath.syncPointee = error
                completion(error)
            }
        }
        
        var j = 0
        
        for keyPath in Self.dataKeyPaths {
            
            if !keyPath.referencing && keyPath.dataType.subKeyPaths.count == 0 {
                j += keyPath.items.count
                continue
            }
            
            let matchArr = keyPath.dataType.primaryKeyPath!.items.indices.map({ index -> String in
                return row[ index + j ] ?? "NULL"
            })
            
            if keyPath.referencing {
                subDispatchGroup.enter()
                keyPath.dataType.selectReferencedPath(matchClause: matchArr, on: connectable, item: &item, keyPathToItem: keyPath.keyPath, completion: completionBlock)
            } else if keyPath.dataType.subKeyPaths.count > 0 {
                subDispatchGroup.enter()
                keyPath.dataType.selectSubPaths(matchClause: matchArr, on: connectable, item: &item, keyPathToItem: keyPath.keyPath, completion: completionBlock)
            }
        }
        
        if Self.subKeyPaths.count > 0 {
            let matchArr = Self.primaryKeyPath!.items.indices.map { return row[ $0 ] ?? "NULL" }
            
            subDispatchGroup.enter()
            selectSubPaths(matchClause: matchArr, on: connectable, item: &item, keyPathToItem: \Self.self, completion: completionBlock)
        }
        
        
        subDispatchGroup.notify(queue: connectable.defaultDispatchQueue, execute: {
            if errorInSubPath.syncPointee == nil {
                item.postProcess (on: connectable) { error in
                    if errorInSubPath.syncPointee == nil {
                        errorInSubPath.syncPointee = error
                    }
                    
                    rowGroup.leave()
                    callback(item)
                }
            }
            
        })
        
    }
    fileprivate static func selectReferencedPath <K: SQLDataConvertible> (matchClause arr: [String], on connectable: SQLConnectable, item: UnsafeMutablePointer<K>, keyPathToItem: AnyKeyPath, completion: @escaping (Error?) -> Void) {
        
        var isPointlessQuery = false
        
        let pkPath = primaryKeyPath!
        let matchClause = pkPath.items.indices.map({ i -> String in
            if pkPath.items[i].column.flags.contains(.notNull) && arr[i] == "NULL" {
                isPointlessQuery = true
            }
            return "\(tableName).'\(pkPath.items[i].column.name)'=='\(arr[i])'"
        })
        
        if isPointlessQuery {
            completion(nil)
            return
        }
        
        var referenceFound = keyPathToItem is WritableKeyPath<K, Self?>
        select(where: "\(matchClause.joined(separator: ", ")) LIMIT 1", on: connectable, row: { row in
            referenceFound = true
            Self.copy(fromObject: row, toObject: &item.pointee, keyPath: keyPathToItem)
        }) { error in
            if error == nil, !referenceFound {
                completion(SQLData.Error.referenceNotFound)
            } else {
                completion(error)
            }
            
            
        }
        
    }
    
    fileprivate static func selectSubPaths <K: SQLDataConvertible> (matchClause arr: [String], on connectable: SQLConnectable, item: UnsafeMutablePointer<K>, keyPathToItem: AnyKeyPath, completion: @escaping (Error?) -> Void) {
        
        var error: Error?
        let group = DispatchGroup()
        
        defer {
            group.notify(queue: connectable.defaultDispatchQueue, execute: { if error == nil { completion(nil) } })
        }
        
        for subKeyPath in subKeyPaths {
            group.enter()

            let kp = keyPathToItem.appending(path: subKeyPath.keyPath)!
            let query = subKeyPath.selectQuery(matching: arr)
            subKeyPath.dataType.setSubKeyPath(query, on: connectable, keyPath: kp, item: item) { err in
                if let err = err {
                    error = err
                    completion(error)
                }
                group.leave()
            }
        }
        
    }
    private static func setSubKeyPath <K: SQLDataConvertible> (_ q: String, on connectable: SQLConnectable, keyPath: AnyKeyPath, item: UnsafeMutablePointer<K>, completion: @escaping (Error?) -> Void) {
        
        let path = keyPath as! WritableKeyPath<K, [Self]>
        select(q, on: connectable, row: { row in item.pointee[keyPath: path].append(row) }) { error in completion(error) }
    }
    
}
