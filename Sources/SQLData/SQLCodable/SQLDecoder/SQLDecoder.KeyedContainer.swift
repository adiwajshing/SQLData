//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 1/21/20.
//

import Foundation

extension SQLDecoder {
    
    struct SQLKeyedContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
        typealias Key = K
        
        let allKeys: [K] = []
        
        let path: DataPath
        let data: SQLEncodedData
        let codingPath: [CodingKey]
        
        func contains(_ key: K) -> Bool {
            
            switch valueType(for: key) {
            case .notPresent:
                return false
            default:
                return true
            }
        }
        
        func decodeNil(forKey key: K) throws -> Bool {
            
            switch valueType(for: key) {
            case .notPresent:
                return true
            default:
                return false
            }
        }
        
        func decode(_ type: Bool.Type, forKey key: K) throws -> Bool { try decode(type, key: key) }
        
        func decode(_ type: String.Type, forKey key: K) throws -> String { try decode(type, key: key) }
        func decode(_ type: Double.Type, forKey key: K) throws -> Double { try decode(type, key: key) }
        func decode(_ type: Float.Type, forKey key: K) throws -> Float { try decode(type, key: key) }
        
        func decode(_ type: Int.Type, forKey key: K) throws -> Int { try decode(type, key: key) }
        func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 { try decode(type, key: key) }
        func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 { try decode(type, key: key) }
        func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 { try decode(type, key: key) }
        func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 { try decode(type, key: key) }
        
        func decode(_ type: UInt.Type, forKey key: K) throws -> UInt { try decode(type, key: key) }
        func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 { try decode(type, key: key) }
        func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 { try decode(type, key: key) }
        func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 { try decode(type, key: key) }
        func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 { try decode(type, key: key) }
        
        func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
            var codingPath = self.codingPath
            codingPath.append(key)
            
            let decoder: SQLDecoder
            switch valueType(for: key) {
            case .referenced(let keys):
                let comps = keys.first!.components(separatedBy: sqlKeySeperator)
                let tableName = comps[comps.count-2]
                
                let t = try table()
                let tableKeys = keys.map { ($0, $0.components(separatedBy: sqlKeySeperator).last!) }
                
                let index = data.dictionary[tableName]?.firstIndex(where: { row in
                    for (myTableKey, newTableKey) in tableKeys {
                        if row[newTableKey] != t[myTableKey] { return false }
                    }
                    return true
                })
                guard index != nil else {
                    throw DecodingError.valueNotFound(type, .init(codingPath: codingPath, debugDescription: "Referenced value not found"))
                }
                
                let dataPath = DataPath(tableName: tableName, key: "", row: index!)
                decoder = SQLDecoder(path: dataPath, data: data, codingPath: codingPath)
                break
            case .presentAsStructure(let keys):
                let comps = keys.first!.components(separatedBy: sqlKeySeperator)
                let fIndex = comps.firstIndex(of: key.stringValue)
                
                var dataPath = path
                dataPath.key = comps[0...(fIndex!)].joined(separator: sqlKeySeperator)
                decoder = SQLDecoder(path: dataPath, data: data, codingPath: codingPath)
                break
           /* case .presentAsSingleValue(_):
                var dataPath = path
                dataPath.key = path.keyString(for: key)
                decoder = SQLDecoder(path: dataPath, data: data, codingPath: codingPath)
                break */
            default:
                var dataPath = path
                dataPath.key = path.keyString(for: key)
                decoder = SQLDecoder(path: dataPath, data: data, codingPath: codingPath)
                break
            }
            return try T(from: decoder)
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            fatalError()
        }
        
        func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
            fatalError()
        }
        
        func superDecoder() throws -> Decoder {
            fatalError()
        }
        
        func superDecoder(forKey key: K) throws -> Decoder {
            fatalError()
        }
        
        
        private func decode<T: SQLColumnConvertible> (_ t: T.Type, key: CodingKey) throws -> T {
            
            guard let stringValue = try table()[ path.keyString(for: key) ] else {
                var codingPath = self.codingPath
                codingPath.append(key)
                throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: "KEY NOT PRESENT") )
            }
            
            return try T(sqlValue: stringValue)
        }
        private func table () throws -> [String:String] {
            guard let dict = data.dictionary[path.tableName]?[path.row] else {
                throw DecodingError.dataCorrupted( .init(codingPath: codingPath, debugDescription: "Table not found: \(path.tableName)") )
            }
            return dict
        }
        private func valueType (for key: CodingKey) -> ValueType {
            guard let table = try? table() else { return .notPresent }
            
            let keyStr = path.keyString(for: key)
            if let value = table[keyStr] {
                return value == sqlNullValue ? .notPresent : .presentAsSingleValue(keyStr)
            }
            
            var keyStringPrefix = sqlRefKeyPrefix + keyStr + sqlKeySeperator
            var keys = table.keys.filter { $0.hasPrefix(keyStringPrefix) }
            if keys.count > 0 {
                return .referenced(keys)
            }
            
            keyStringPrefix = keyStr + sqlKeySeperator
            keys = table.keys.filter { $0.hasPrefix(keyStringPrefix) }
            return keys.count > 0 ? .presentAsStructure(keys) : .notPresent
        }
        enum ValueType {
            case notPresent
            case presentAsSingleValue (String)
            case referenced ([String])
            case presentAsStructure ([String])
        }
        
    }
}
