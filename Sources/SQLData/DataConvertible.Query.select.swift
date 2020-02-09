//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 1/6/20.
//

import Foundation
import Promises

public extension SQLDataConvertible {
    
    static func columnsToSelect () -> String {
        return columnsToSelect(keyPaths: dataKeyPaths)
    }
    static func columnsToSelect (keyPaths: [SQLData.KeyPathDataColumn]) -> String {
        return keyPaths.flatMap { return $0.items.map({ "\(tableName).'\($0.column.name)'" }) }.joined(separator: ", ")
    }
    
    static func selectMainTableQuery (appending clause: String) -> String {
        return selectMainTableQuery(keyPaths: dataKeyPaths, appending: clause)
    }
    static func selectMainTableQuery (keyPaths: [SQLData.KeyPathDataColumn], appending clause: String) -> String {
        return "SELECT \(columnsToSelect(keyPaths: keyPaths)) FROM \(tableName)\(clause)"
    }
    static func select <T: SQLDataConvertible> (_ keyPath: WritableKeyPath<Self, T>, where whereClause: String, on connectable: SQLConnectable, row callback: @escaping (T) -> Void, include: SQLDataIOOptions) -> Promise<Void> {
        return select(keyPath, appending: whereClause.isEmpty ? "" : " WHERE \(whereClause)", on: connectable, row: callback, include: include)
    }
    static func select <T: SQLDataConvertible> (_ keyPath: WritableKeyPath<Self, T>, appending clause: String, on connectable: SQLConnectable, row callback: @escaping (T) -> Void, include: SQLDataIOOptions) -> Promise<Void> {
        
        if let keyPath = dataKeyPaths.first(where: { $0.keyPath == keyPath }) {
            return T.select(selectMainTableQuery(keyPaths: [keyPath], appending: clause), on: connectable, row: callback, include: include)
        } else {
            return Promise<Void>(SQLData.Error.error("key path not present"))
        }
        
    }
    static func select (countWhere whereClause: String, on connectable: SQLConnectable) -> Promise<Int> {
        let q = "SELECT COUNT(*) FROM \(tableName) \(whereClause.isEmpty ? "" : "WHERE \(whereClause)")"
        return Int.select(q, on: connectable, include: []).then (on: connectable.defaultDispatchQueue) { $0.first! }
    }
    static func select (appending clause: String, on connectable: SQLConnectable, include: SQLDataIOOptions) -> Promise<[Self]> {
        return select(selectMainTableQuery(appending: clause), on: connectable, include: include)
    }
    static func select (where whereClause: String, on connectable: SQLConnectable, include: SQLDataIOOptions) -> Promise<[Self]> {
        return select(appending: whereClause.isEmpty ? "" : " WHERE \(whereClause)", on: connectable, include: include)
    }
    static func select (_ q: String, on connectable: SQLConnectable, include: SQLDataIOOptions) -> Promise<[Self]> {
        var rows = [Self]()
        return select(q, on: connectable, row: { rows.append($0) }, include: include).then(on: connectable.defaultDispatchQueue) { rows }
    }
    static func select (where whereClause: String, on connectable: SQLConnectable, row callback: @escaping (Self) -> Void, include: SQLDataIOOptions) -> Promise<Void> {
        return select(selectMainTableQuery(appending: whereClause.isEmpty ? "" : " WHERE \(whereClause)"), on: connectable, row: callback, include: include)
    }
    static func select (_ q: String, on connectable: SQLConnectable, row callback: @escaping (Self) -> Void, include: SQLDataIOOptions) -> Promise<Void> {
        
        return Promise<Void>(on: connectable.defaultDispatchQueue) { fulfill, reject in
            
            var p = Promise<Void>(())
            _ = connectable.query(q, row: { row in
               // print(row)
                p = p.then (on: connectable.defaultDispatchQueue) {
                    loadFromRow(row: row, connectable: connectable, include: include).then(on: connectable.defaultDispatchQueue) { callback($0) }
                }
                p.catch(on: connectable.defaultDispatchQueue) { reject($0) }
                
            })
            .catch(on: connectable.defaultDispatchQueue, { reject($0) })
            .then(on: connectable.defaultDispatchQueue) { return p.then(on: connectable.defaultDispatchQueue, fulfill) }
        }
    }
    fileprivate static func loadFromRow (row: [String?], connectable: SQLConnectable, include: SQLDataIOOptions) -> Promise<Self> {

        let promise = Promise<Self>(on: connectable.defaultDispatchQueue) { fulfill, reject in
            var item = Self()
            _ = item.read(mainRow: row)
            
            var errorInQ: Error?
            let subDispatchGroup = DispatchGroup()
            
            let completionBlock = subDispatchGroup.leave
            let errorBlock = { (error: Error) in
                subDispatchGroup.leave()
                
                errorInQ = error
                reject(error)
            }
            
            if include.contains(.referencedValues) || include.contains(.subValues) {
                
                var j = 0
                for keyPath in Self.dataKeyPaths {
                    
                    if keyPath.dataType.primaryKeyPath == nil {
                        j += keyPath.items.count
                        continue
                    }
                    
                    let matchArr = keyPath.dataType.primaryKeyPath!.items.indices.map({ index -> String in
                        return row[ index + j ] ?? "NULL"
                    })
                    j += keyPath.items.count
                    
                    let promise: Promise<Void>
                    
                    if keyPath.referencing, include.contains(.referencedValues) {
                        subDispatchGroup.enter()
                        promise = keyPath.dataType.selectReferencedPath(matchClause: matchArr, on: connectable, item: &item, keyPathToItem: keyPath.keyPath, include: include)
                    } else if include.contains(.subValues) {
                        subDispatchGroup.enter()
                        promise = keyPath.dataType.selectSubPaths(matchClause: matchArr, on: connectable, item: &item, keyPathToItem: keyPath.keyPath, include: include)
                    } else {
                        continue
                    }
                    
                    promise.then(on: connectable.defaultDispatchQueue, completionBlock).catch(on: connectable.defaultDispatchQueue, errorBlock)
                }
                
                if Self.subKeyPaths.count > 0, include.contains(.subValues) {
                    let matchArr = Self.primaryKeyPath!.items.indices.map { return row[ $0 ] ?? "NULL" }
                    
                    subDispatchGroup.enter()
                    selectSubPaths(matchClause: matchArr, on: connectable, item: &item, keyPathToItem: \Self.self, include: include)
                        .then(on: connectable.defaultDispatchQueue, completionBlock)
                        .catch(on: connectable.defaultDispatchQueue, errorBlock)
                }
                
            }
            
            subDispatchGroup.notify(queue: connectable.defaultDispatchQueue) {
                if errorInQ == nil {
                    fulfill(item)
                }
            }
        }
        
        return promise
    }
    fileprivate static func selectReferencedPath <T: SQLDataConvertible> (matchClause arr: [String], on connectable: SQLConnectable, item: UnsafeMutablePointer<T>, keyPathToItem: AnyKeyPath, include: SQLDataIOOptions) -> Promise<Void> {
        var isPointlessQuery = false
        
        let pkPath = primaryKeyPath!
        let matchClause = pkPath.items.indices.map({ i -> String in
            if pkPath.items[i].column.flags.contains(.notNull) && arr[i] == "NULL" {
                isPointlessQuery = true
            }
            return "\(tableName).'\(pkPath.items[i].column.name)'=='\(arr[i])'"
        })
        
        if isPointlessQuery {
            return Promise<Void>(on: connectable.defaultDispatchQueue) { fulfill, _ in fulfill(()) }
        }
        
        return
            select(where: "\(matchClause.joined(separator: ", ")) LIMIT 1", on: connectable, include: include)
            .then (on: connectable.defaultDispatchQueue) { rows -> Promise<Void> in
                
                if rows.count > 0 {
                    if let path = keyPathToItem as? WritableKeyPath<T, Self> {
                        item.pointee[keyPath: path].copy(fromObject: rows.first!)
                    } else {
                        let path = keyPathToItem as! WritableKeyPath<T, Optional<Self>>
                        
                        if item.pointee[keyPath: path] == nil {
                            item.pointee[keyPath: path] = rows.first!
                        }
                    }
                }
            
                if rows.count == 0 && keyPathToItem is WritableKeyPath<T, Self> {
                    return Promise<Void>(SQLData.Error.referenceNotFound)
                }
            
                return Promise<Void>(())
            }
        
    }
    
    fileprivate static func selectSubPaths <K: SQLDataConvertible> (matchClause arr: [String], on connectable: SQLConnectable, item: UnsafeMutablePointer<K>, keyPathToItem: AnyKeyPath, include: SQLDataIOOptions) -> Promise<Void> {
        
        var promise = Promise<Void>(())
        for subKeyPath in subKeyPaths {
            let kp = keyPathToItem.appending(path: subKeyPath.keyPath)!
            let query = subKeyPath.selectQuery(matching: arr)
            promise = promise.then(on: connectable.defaultDispatchQueue){ subKeyPath.dataType.setSubKeyPath(query, on: connectable, keyPath: kp, item: item, include: include) }
        }
        return promise
        
    }
    private static func setSubKeyPath <K: SQLDataConvertible> (_ q: String, on connectable: SQLConnectable, keyPath: AnyKeyPath, item: UnsafeMutablePointer<K>, include: SQLDataIOOptions) -> Promise<Void> {
        
        return select(q, on: connectable, row: { row in
            
            item.pointee[keyPath: keyPath as! WritableKeyPath<K, [Self]> ].append(row)
        }, include: include)
    }
    
}
