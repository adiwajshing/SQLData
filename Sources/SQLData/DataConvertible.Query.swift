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
        connectable.query(queries: queries, completion: completion)
    }
    
    static func columnsToSelect () -> String {
        return dataKeyPaths.map({ keyPath in
            
            let columns = keyPath.items.map({ "\(tableName).'\($0.column.name)'"})
            return columns.joined(separator: ", ")
            /*if keyPath.referencing && !(keyPath.dataType is Self) {
                let primaryKeyItems = keyPath.dataType.primaryKeyPath!.items
                let dataTypeTableName = keyPath.dataType.tableName
                let matchClause = columns.indices.map { "\(columns[$0])==\(dataTypeTableName).'\(primaryKeyItems[0])'" }
                
                return "(" + keyPath.dataType.selectMainTableQuery(where: matchClause.joined(separator: " AND ")) + " LIMIT 1)"
            } else {
                return columns.joined(separator: ", ")
            }*/
        }).joined(separator: ", ")
    }
    static func selectMainTableQuery (where whereClause: String) -> String {
        return "SELECT \(columnsToSelect()) FROM \(tableName) \(whereClause.isEmpty ? "" : " WHERE \(whereClause)")"
    }
    
    static func initializeStructure (on connectable: SQLConnectable, completion: @escaping (Error?) -> Void) {
        
        let queries = structureDescription().map({$0.query})
        connectable.query(queries: queries, completion: completion)
    }
    
    static func select (where whereClause: String, on connectable: SQLConnectable, table completion: @escaping (SQLData.Table<Self>?, Error?) -> Void) {
        query(selectMainTableQuery(where: whereClause), on: connectable, table: completion)
    }
    private static func query (_ q: String, on connectable: SQLConnectable, table completion: @escaping (SQLData.Table<Self>?, Error?) -> Void) {
        
        let mainKeyPaths = Self.mainKeyPaths
        let subKeyPaths = Self.subKeyPaths
        
        connectable.query(q) { (columns, rows, error) in
            if let error = error {
                completion(nil, error)
            } else {
                
                let table = SQLData.Table<Self>(count: rows.count)
                
                var rowDispatchGroup = DispatchGroup()
                var errorInSubPath: Error?
                defer {
                    rowDispatchGroup.notify(queue: .global(qos: .background), execute: { if errorInSubPath == nil { completion(table, nil) } })
                }
                
                DispatchQueue.concurrentPerform(iterations: table.rows.count) { i in
                    
                    if errorInSubPath != nil {
                        return
                    }
                    
                    rowDispatchGroup.enter()
                    
                    let row = rows[i]
                    table.rows[i].read(mainRow: rows[i])
                    
                    let subDispatchGroup = DispatchGroup()
                    
                    let completionBlock = { (error: Error?) in
                        subDispatchGroup.leave()
                        
                        if let error = error, errorInSubPath == nil {
                            errorInSubPath = error
                            completion(nil, error)
                        }
                    }
                    
                    for keyPath in mainKeyPaths {
                        
                        let matchArr = keyPath.items.compactMap({ item -> String? in
                            if item.column.flags.contains(.primaryKey) {
                                return row[ columns[item.column.name]! ] ?? "NULL"
                            }
                            return nil
                        })
                        
                        if keyPath.referencing {
                            subDispatchGroup.enter()
                            keyPath.dataType.selectReferencedPath(matchClause: matchArr, on: connectable, table: table, index: i, keyPathToItem: keyPath.keyPath, completion: completionBlock)
                        } else if keyPath.dataType.subKeyPaths.count > 0 {
                            subDispatchGroup.enter()
                            keyPath.dataType.selectSubPaths(matchClause: matchArr, on: connectable, table: table, index: i, keyPathToItem: keyPath.keyPath, completion: completionBlock)
                        }
                    }
                    
                    if subKeyPaths.count > 0 {
                        let matchArr = Self.primaryKeyPath!.items.map { item in
                            return row[ columns[item.column.name]! ]!
                        }
                        
                        subDispatchGroup.enter()
                        selectSubPaths(matchClause: matchArr, on: connectable, table: table, index: i, keyPathToItem: \Self.self,  completion: completionBlock)
                    }
                    
                    
                    subDispatchGroup.notify(queue: connectable.defaultDispatchQueue, execute: {
                        rowDispatchGroup.leave()
                    })
                    
                }
                
            }
        }
    }
    fileprivate static func selectReferencedPath <K: SQLDataConvertible> (matchClause arr: [String], on connectable: SQLConnectable, table: SQLData.Table<K>, index: Int, keyPathToItem: AnyKeyPath, completion: @escaping (Error?) -> Void) {
        
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
        
        select(where: "\(matchClause.joined(separator: ", ")) LIMIT 1", on: connectable) { (subTable, error) in
            if let subTable = subTable {
                
                if let path = keyPathToItem as? WritableKeyPath<K, Self> {
                    if subTable.rows.count > 0 {
                        table.rows[index][keyPath: path] = subTable.rows.first!
                    }
                } else if let path = keyPathToItem as? WritableKeyPath<K, Self?> {
                    table.rows[index][keyPath: path] = subTable.rows.first
                }
                
            }
            completion(error)
        }
        
    }
    fileprivate static func selectSubPaths <K: SQLDataConvertible> (matchClause arr: [String], on connectable: SQLConnectable, table: SQLData.Table<K>, index: Int, keyPathToItem: AnyKeyPath, completion: @escaping (Error?) -> Void) {
        
        var error: Error?
        let group = DispatchGroup()
        
        defer {
            group.notify(queue: connectable.defaultDispatchQueue, execute: { if error == nil { completion(nil) } })
        }
        
        for subKeyPath in subKeyPaths {
            group.enter()

            let kp = keyPathToItem.appending(path: subKeyPath.keyPath)!
            subKeyPath.dataType.setSubKeyPath(
                subKeyPath.selectQuery(matching: arr),
                on: connectable,
                keyPath: kp,
                table: table,
                index: index,
                completion: { err in
                    if let err = err {
                        error = err
                        completion(error)
                    }
                    group.leave()
            })
        }
        
    }
    private static func setSubKeyPath <K: SQLDataConvertible> (_ q: String, on connectable: SQLConnectable, keyPath: AnyKeyPath, table: SQLData.Table<K>, index: Int, completion: @escaping (Error?) -> Void) {
        
        Self.query(q, on: connectable) { (subTable, error) in
            if let subTable = subTable {
                let path = keyPath as? WritableKeyPath<K, [Self]>
                table.rows[index][keyPath: path!] = subTable.rows
            }
            
            completion(error)
        }
    }
    
}
