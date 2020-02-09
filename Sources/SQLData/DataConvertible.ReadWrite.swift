//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 12/30/19.
//

import Foundation

public extension SQLDataConvertible {

    internal mutating func read (mainRow row: [String?]) -> Bool {
        
        let dataKeyPaths = Self.dataKeyPaths
        
        var i = 0
        for keyPath in dataKeyPaths {
            
            if keyPath.referencing {
                i += keyPath.items.count
                continue
            }
            
            if !keyPath.dataType.read(object: &self, row: row[i..<(i+keyPath.items.count)], keyPath: keyPath.keyPath, items: keyPath.items) {
                return false
            }
            i += keyPath.items.count
        }
        
        return true
    }
    private static func read <T: SQLDataConvertible> (object: inout T, row: ArraySlice<String?>, keyPath: AnyKeyPath, items: [SQLData.KeyPathItemColumn]) -> Bool {
        
        if let K = Self.self as? SQLItemConvertible.Type {

            return K.write(keyPath: keyPath, object: &object, stringValue: row.first!, column: items.first!.column)
        }
        
        var obj = Self.init()
        
        if let kp = keyPath as? WritableKeyPath<T, Self> {
            if obj.read(mainRow: Array(row)) {
                object[keyPath: kp] = obj
            } else {
                return false
            }
            
        } else {
            let kp = keyPath as! WritableKeyPath<T, Self?>
            let areAllNull = row.firstIndex(where: { $0 != nil }) == nil
            if areAllNull {
                object[keyPath: kp] = nil
            } else {
                if obj.read(mainRow: Array(row)) {
                    object[keyPath: kp] = obj
                } else {
                    return false
                }
                
            }
            
        }
        return true
    }
    internal mutating func copy (fromObject: Self) {
        
        let dataKeyPaths = Self.dataKeyPaths
        for keyPath in dataKeyPaths {
            keyPath.dataType.copy(from: fromObject, to: &self, keyPath: keyPath.keyPath)
        }
        
        for keyPath in Self.subKeyPaths {
            keyPath.dataType.copy(from: fromObject, to: &self, keyPath: keyPath.keyPath)
        }
    }
    private static func copy<T: SQLDataConvertible> (from: T, to: inout T, keyPath: AnyKeyPath) {
        
        if let path = keyPath as? WritableKeyPath<T, Self> {
            
            if Self.self is SQLItemConvertible.Type {
                to[keyPath: path] = from[keyPath: path]
            } else {
                to[keyPath: path].copy(fromObject: from[keyPath: path])
            }

        } else if let path = keyPath as? WritableKeyPath<T, [Self]> {
            to[keyPath: path] = from[keyPath: path]
        } else {
            let path = keyPath as! WritableKeyPath<T, Optional<Self>>
            to[keyPath: path] = from[keyPath: path]
        }
        
    }
    func insertQueries (include: SQLDataIOOptions) -> [String] {
        return Self.insertQueries(from: stringDescription(include: include))
    }
    static func insertQueries (from description: [String: [[String:String]]]) -> [String] {
        
        return description.flatMap { (table, rows) in
            rows.map { row in
                let keys = row.keys
                return "INSERT INTO \(table) (\(keys.joined(separator: ", "))) VALUES(\(keys.map{ row[$0]! }.joined(separator: ", ")))"
            }
        }
    }
    
    func stringDescription (include: SQLDataIOOptions) -> [String: [[String: String]]] {

        var values = [String: [[String:String]]]()
        var mainValues = [String: String]()

        var keyPaths = Self.mainKeyPaths
        if let pKPath = Self.primaryKeyPath {
            keyPaths.append(pKPath)
        }
        for keyPath in keyPaths {
            mainValues.merge(self.dictionary(items: keyPath.items), uniquingKeysWith: {s0, s1 in return s0})
            
            if let object = keyPath.dataType.getObject(object: self, keyPath: keyPath.keyPath) {
                
                if include.contains(.referencedValues), keyPath.referencing {
                    let desc = object.stringDescription(include: include)
                    values.merge(desc, uniquingKeysWith: {s0, s1 in return s0+s1})
                } else if include.contains(.subValues), let value = self[keyPath: keyPath.keyPath] as? SQLDataConvertible, keyPath.dataType.subKeyPaths.count > 0 {
                    values.merge(value.subDescriptions(include: include), uniquingKeysWith: {s0,s1 in return s0+s1 })
                }
                
            }
            
        }
        values.merge(subDescriptions(include: include), uniquingKeysWith: { s0, s1 in return s0+s1 })

        var v = values[Self.tableName] ?? [[String:String]]()
        v.append(mainValues)
        values[Self.tableName] = v
        
        return values
    }
    internal func subDescriptions (include: SQLDataIOOptions) -> [String: [[String: String]]] {

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
                
                if include.contains(.referencedValues), keyPath.referencing {
                    let desc = array[i].stringDescription(include: include)
                    values.merge(desc, uniquingKeysWith: {s0, s1 in return s0+s1})
                } else if include.contains(.subValues),  type(of: array[i]).subKeyPaths.count > 0 {
                    values.merge(array[i].subDescriptions(include: include), uniquingKeysWith: {s0,s1 in return s0+s1})
                }
            }
            values[keyPath.keyName] = rows
        }
        
        return values
    }
    internal func subDescriptions (keyPath: SQLData.KeyPathArrayColumn, value: SQLDataConvertible, index i: Int, include: SQLDataIOOptions) -> [String: [[String: String]]] {
        var values = [String: [[String: String]]]()
        
        var row = self.dictionary(items: keyPath.mappingKeyPath.items)
        
        if let indexingColumn = keyPath.indexingColumn {
            row[indexingColumn.name] = Int64(i).stringValue(for: Int64.defaultDataType)
        }
        
        row.merge(value.dictionary(items: keyPath.accessedItems), uniquingKeysWith: {s0, s1 in return s0})
        
        if include.contains(.referencedValues), keyPath.referencing {
            let desc = value.stringDescription(include: include)
            values.merge(desc, uniquingKeysWith: {s0, s1 in return s0+s1})
        } else if include.contains(.subValues), type(of: value).subKeyPaths.count > 0 {
            values.merge(value.subDescriptions(include: include), uniquingKeysWith: {s0,s1 in return s0+s1})
        }
        values[keyPath.keyName] = [row]
        return values
    }
    
    func dictionary (items: [SQLData.KeyPathItemColumn]) -> [String:String] {
        var dict = [String:String]()
        for item in items {
            
            if let value = self.obtainValue(from: item.path.suffix(from: 0)) {
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
    
    internal func obtainValue (from path: ArraySlice<(AnyKeyPath, SQLDataConvertible.Type)>) -> SQLItemConvertible? {
        return path.first!.1.obtainValue(from: path, obj: self)
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
