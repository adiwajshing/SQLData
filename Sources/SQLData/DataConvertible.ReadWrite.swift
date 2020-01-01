//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 12/30/19.
//

import Foundation

public extension SQLDataConvertible {

    internal mutating func read (mainRow row: [String?]) {
        
        let dataKeyPaths = Self.dataKeyPaths
        
        var i = 0
        for keyPath in dataKeyPaths {
            if keyPath.referencing {
                i += keyPath.items.count
                continue
            }
            for item in keyPath.items {
                if let rowItem = row[i] {
                    var keyPath: AnyKeyPath = item.path.first!.0
                    for (kp, dataType) in item.path.suffix(from: 1) {
                        keyPath = dataType.appending(subKeyPath: kp, toKeyPath: keyPath, object: &self)!
                    }
                    let itemType = item.path.last!.1 as! SQLItemConvertible.Type
                    itemType.write(keyPath: keyPath, object: &self, stringValue: rowItem, column: item.column)
                }
                
                i += 1
            }
        }
    }
    private static func appending<T: SQLDataConvertible> (subKeyPath: AnyKeyPath, toKeyPath keyPath: AnyKeyPath, object: inout T) -> AnyKeyPath? {
        if let keyPath = keyPath as? WritableKeyPath<T, Self> {
            return (keyPath as AnyKeyPath).appending(path: keyPath)!
        } else if let keyPath = keyPath as? WritableKeyPath<T, Optional<Self>> {
            if object[keyPath: keyPath] == nil {
                object[keyPath: keyPath] = Self.init()
            }
            return (keyPath.appending(path: \Optional<Self>.unsafelyUnwrapped) as AnyKeyPath).appending(path: keyPath)!
        } else {
            assertionFailure("SHOULD NOT EVER OCCUR")
            return nil
        }
    }

    
    func insertQueries (includeReferences: Bool) -> [String] {
        
        var queries = [String]()
        
        for (table, rows) in stringDescription(includeReferences: includeReferences) {
            
            for row in rows {
                var columns = [String]()
                var items = [String]()
                
                for (c, i) in row {
                    columns.append(c)
                    items.append(i)
                }
                queries.append("INSERT INTO '\(table)' ('\(columns.joined(separator: "', '"))') VALUES(\(items.joined(separator: ", ")))")
                
            }
            
            
        }
        
        return queries
    }
    
    func stringDescription (includeReferences: Bool) -> [String: [[String: String]]] {

        var values = [String: [[String:String]]]()
        var mainValues = [String: String]()

        var keyPaths = Self.mainKeyPaths
        if let pKPath = Self.primaryKeyPath {
            keyPaths.append(pKPath)
        }
        for keyPath in keyPaths {
            mainValues.merge(self.dictionary(items: keyPath.items), uniquingKeysWith: {s0, s1 in return s0})
            
            if let object = keyPath.dataType.getObject(object: self, keyPath: keyPath.keyPath) {
                
                if includeReferences, keyPath.referencing {
                    let desc = object.stringDescription(includeReferences: includeReferences)
                    values.merge(desc, uniquingKeysWith: {s0, s1 in return s0+s1})
                } else if let value = self[keyPath: keyPath.keyPath] as? SQLDataConvertible, keyPath.dataType.subKeyPaths.count > 0 {
                    values.merge(value.subDescriptions(includeReferences: includeReferences), uniquingKeysWith: {s0,s1 in return s0+s1 })
                }
                
            }
            
        }
        values.merge(subDescriptions(includeReferences: includeReferences), uniquingKeysWith: { s0, s1 in return s0+s1 })

        var v = values[Self.tableName] ?? [[String:String]]()
        v.append(mainValues)
        values[Self.tableName] = v
        
        return values
    }
    fileprivate func subDescriptions (includeReferences: Bool) -> [String: [[String: String]]] {

        var values = [String: [[String: String]]]()
        
        for keyPath in Self.subKeyPaths {
            let array = self[keyPath: keyPath.keyPath] as! [SQLDataConvertible]
            
            var rows = [[String:String]]()
            let mappedKeys = self.dictionary(items: keyPath.mappingKeyPath.items)
            
            for i in array.indices {
                var row = mappedKeys
                
                if let indexingColumn = keyPath.indexingColumn {
                    row[indexingColumn.name] = Int64(i).stringValue(for: Int64.defaultDataType)
                }
                
                row.merge(array[i].dictionary(items: keyPath.accessedItems), uniquingKeysWith: {s0, s1 in return s0})
                
                rows.append(row)
                
                if includeReferences, keyPath.referencing {
                    let desc = array[i].stringDescription(includeReferences: includeReferences)
                    values.merge(desc, uniquingKeysWith: {s0, s1 in return s0+s1})
                } else if type(of: array[i]).subKeyPaths.count > 0 {
                    values.merge(array[i].subDescriptions(includeReferences: includeReferences), uniquingKeysWith: {s0,s1 in return s0+s1})
                }
            }
            values[keyPath.keyName] = rows
            
        }

        return values
    }
    
    func dictionary (items: [SQLData.KeyPathItemColumn]) -> [String:String] {
        var dict = [String:String]()
        for item in items {
            let dataType = item.path.first!.1
            if let value = dataType.obtainValue(from: item.path.suffix(from: 0), obj: self) {
                dict[item.column.name] = value.stringValue(for: item.column.dataType)
            } else {
                dict[item.column.name] = "NULL"
            }
            
        }
        return dict
    }
    internal static func getObject <T: SQLDataConvertible> (object: T, keyPath: AnyKeyPath) -> Self? {
        let value: Self
        if let keyPath = keyPath as? KeyPath<T, Self> {
            value = object[keyPath: keyPath]
        } else if let keyPath = keyPath as? KeyPath<T, Optional<Self>>, let v2 = object[keyPath: keyPath] {
            value = v2
        } else {
            //print("\(path.first!), \(Self)")
            return nil
        }
        return value
    }
    
    internal static func obtainValue<T: SQLDataConvertible> (from path: ArraySlice<(AnyKeyPath, SQLDataConvertible.Type)>, obj: T) -> SQLItemConvertible? {
        
        guard let value = Self.getObject(object: obj, keyPath: path.first!.0) else {
            return nil
        }
        
        if let item = value as? SQLItemConvertible {
            return item
        }
        
        let nPath = path.suffix(from: 1)
        
        if let nextType = nPath.first?.1 {
            return nextType.obtainValue(from: nPath, obj: value)
        }
        
        return nil
    }
    
}
extension AnyKeyPath {
    
    static func valueUnwrappedType () -> SQLDataConvertible.Type? {
        let nextType: SQLDataConvertible.Type
        if let tp = Self.valueType as? SQLDataConvertible.Type {
            nextType = tp
        } else if let tp = Self.valueType as? Optional<SQLDataConvertible>.Type {
            print("hello")
            nextType = tp.wrappedType() as! SQLDataConvertible.Type
        } else {
            return nil
        }
        return nextType
    }
    
}

extension Optional {
    static func wrappedType() -> Wrapped.Type {
        return Wrapped.self
        
    }
}
