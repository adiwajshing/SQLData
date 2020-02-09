//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 12/31/19.
//

import Foundation
import Promises

public extension SQLDataConvertible {
    
    func insert (on connectable: SQLConnectable, include: SQLDataIOOptions = []) -> Promise<Void> {
        let queries = self.insertQueries(include: include)
        return connectable.query(queries: queries)
    }
    
    func delete (on connectable: SQLConnectable, include: SQLDataIOOptions) -> Promise<Void> {
        
        let tableName = Self.tableName
        
        let matchClauses: [String]
        if let keyPath = Self.primaryKeyPath {
            matchClauses = keyPath.items.map({ "\(tableName).'\($0.column.name)'=\(obtainValue(from: $0.path.suffix(from: 0))?.stringValue(for: $0.column.dataType) ?? "NULL")" })
        } else {
            matchClauses = Self.mainKeyPaths.flatMap({ $0.items.map{ "\(tableName).'\($0.column.name)'=\(obtainValue(from: $0.path.suffix(from: 0))?.stringValue(for: $0.column.dataType) ?? "NULL")" } })
        }
        
        return connectable.query("DELETE FROM \(tableName) WHERE \(matchClauses.joined(separator: ", "))", row: nil)
        
    }
    func delete <T: SQLDataConvertible> (indexes: [Int], on connectable: SQLConnectable, ofSubKeyPath keyPath: WritableKeyPath<Self, [T]>) -> Promise<Void> {
        
        var arr = self[keyPath: keyPath]
        let removedValues = indexes.map { arr.remove(at: $0) }
        let path = Self.subKeyPaths.first(where: { keyPath == $0.keyPath })!
        
        let queries = removedValues.map({ value -> String in
            var columns = path.mappingKeyPath.items.map { item -> String in
                let val = self.obtainValue(from: item.path.suffix(from: 0))?.stringValue(for: item.column.dataType)
                return "\(item.column.name)=\(val ?? "NULL")"
            }
            columns.append(contentsOf: path.dataType.mainKeyPaths.flatMap({ path in
                path.items.map { item -> String in
                    let val = value.obtainValue(from: item.path.suffix(from: 0))?.stringValue(for: item.column.dataType)
                    return "\(item.column.name)=\(val ?? "NULL")"
                }
            }))
            return "DELETE FROM \(path.keyName) WHERE \(columns.joined(separator: " AND "))"
        })
        return connectable.query(queries: queries)
    }
    func update (_ keyPaths: PartialKeyPath<Self>..., on connectable: SQLConnectable) -> Promise<Void> {
        return self.update(keyPaths, on: connectable)
    }
    func update (_ keyPaths: [PartialKeyPath<Self>], on connectable: SQLConnectable) -> Promise<Void> {
        
        let tableName = Self.tableName
        let dataPaths = Self.mainKeyPaths
        
        let setClauses = keyPaths.flatMap { path -> [String] in
            let kp = dataPaths.first(where: { $0.keyPath == path })!
            return kp.items.map({ "\($0.column.name)=\( obtainValue(from: $0.path.suffix(from: 0))?.stringValue(for: $0.column.dataType) ?? "NULL" )" })
        }
        let matchClause = Self.primaryKeyPath!.items.map({
            "\($0.column.name)==\( obtainValue(from: $0.path.suffix(from: 0))?.stringValue(for: $0.column.dataType) ?? "NULL" )"
        })
        
        let q = "UPDATE \(tableName) SET \(setClauses.joined(separator: ", ")) WHERE \(matchClause.joined(separator: ", "))"

        return connectable.query(q, row: nil)
    }
    func update <T: SQLDataConvertible> (valueAtIndex index: Int, to newValue: T, atSubKeyPath keyPath: WritableKeyPath<Self, [T]>) -> Promise<Void> {
        fatalError()
    }
    
    func insert <T: SQLDataConvertible> (appending value: T, toSubKeyPath keyPath: WritableKeyPath<Self, [T]>, on connectable: SQLConnectable, include: SQLDataIOOptions) -> Promise<Void> {
       // self[keyPath: keyPath].append(value)
        
        let subPath = Self.subKeyPaths.first(where: { $0.keyPath == keyPath })!
        let desc = subDescriptions(keyPath: subPath, value: value, index: self[keyPath: keyPath].count, include: include)
        let queries = Self.insertQueries(from: desc)
        
        return connectable.query(queries: queries)
    }
    static func insert (_ data: [Self], on connectable: SQLConnectable, include: SQLDataIOOptions) -> Promise<Void> {
        return Promise<Void>(on: connectable.defaultDispatchQueue) { fulfill, reject in
            let group = DispatchGroup()
            
            var errorInPath: Error?
            for i in data.indices {
                group.enter()
                data[i].insert(on: connectable, include: include)
                .catch(on: connectable.defaultDispatchQueue) { error in
                    if errorInPath == nil {
                        group.leave()
                        errorInPath = error
                        reject(error)
                    }
                }
                .then(on: connectable.defaultDispatchQueue, group.leave)
            }
            group.notify(queue: connectable.defaultDispatchQueue) { fulfill(()) }
        }
    }
    static func initializeStructure (on connectable: SQLConnectable) -> Promise<Void> {
        let queries = structureDescription().map({$0.query})
        return connectable.query(queries: queries)
    }
    
}
