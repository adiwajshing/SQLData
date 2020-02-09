//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 1/23/20.
//

import Foundation

extension SQLEncoder {
    
    struct KeyedContainer<K: CodingKey>: KeyedEncodingContainerProtocol {
        
        typealias Key = K
        
        let codingPath: [CodingKey]
        let path: DataPath
        let encoder: SQLEncoder
        
        mutating func encodeNil(forKey key: K) throws {
            /*if let ref = try getReferencing(key: key, value: value) {
                let keyString = referencingKeyName(key: key, tableName: ref.0, fromCodingKey: ref.1, toCodingKey: ref.2)
                try encode(sqlNullValue, keyString: keyString)
            } else {
                try encode(sqlNullValue, keyString: path.keyString(for: key))
            }*/
        }
        
        mutating func encode(_ value: Bool, forKey key: K) throws { try encode(value, key: key) }
        mutating func encode(_ value: String, forKey key: K) throws { try encode(value, key: key) }
        mutating func encode(_ value: Double, forKey key: K) throws { try encode(value, key: key) }
        mutating func encode(_ value: Float, forKey key: K) throws { try encode(value, key: key) }
        mutating func encode(_ value: Int, forKey key: K) throws { try encode(value, key: key) }
        mutating func encode(_ value: Int8, forKey key: K) throws { try encode(value, key: key) }
        mutating func encode(_ value: Int16, forKey key: K) throws { try encode(value, key: key) }
        mutating func encode(_ value: Int32, forKey key: K) throws { try encode(value, key: key) }
        mutating func encode(_ value: Int64, forKey key: K) throws { try encode(value, key: key) }
        mutating func encode(_ value: UInt, forKey key: K) throws { try encode(value, key: key) }
        mutating func encode(_ value: UInt8, forKey key: K) throws { try encode(value, key: key) }
        mutating func encode(_ value: UInt16, forKey key: K) throws { try encode(value, key: key) }
        mutating func encode(_ value: UInt32, forKey key: K) throws { try encode(value, key: key) }
        mutating func encode(_ value: UInt64, forKey key: K) throws { try encode(value, key: key) }
        
        mutating func encode<T>(_ value: T, forKey key: K) throws where T : Encodable {
           // print(T.self)
            var codingPath = self.codingPath
            codingPath.append(key)
            
            if let ref = try getReferencing(key: key, value: value) {
                let tableName = ref.0
                let row = encoder.data.dictionary[tableName]?.count ?? 0
                let path = DataPath(tableName: tableName, key: "", row: row)
                
                let encoder = SQLEncoder(T.self, path: path, data: self.encoder.data, codingPath: codingPath)
                try value.encode(to: encoder)
                
                let refValue = encoder.data.dictionary[tableName]!.last![ ref.2.stringValue ]!
                let keyString = referencingKeyName(key: key, tableName: tableName, fromCodingKey: ref.1, toCodingKey: ref.2)
                try encode(refValue, keyString: keyString)
            } else {
                var path = self.path
                path.key = path.keyString(for: key)
                
                var additionalOptions: [CodingUserInfoKey: Any] = [:]
                if let pk = encoder.userInfo[ .primaryKey ] as? String {
                    let key = self.path.keyString(for: K(stringValue: pk)!)
                    let value = encoder.data.dictionary[self.path.tableName]![self.path.row][key]!
                    additionalOptions[.refPrimaryKey] = (path.tableName + sqlKeySeperator + key, value)
                }

                let encoder = SQLEncoder(T.self, path: path, data: self.encoder.data, codingPath: codingPath, additionalOptions: additionalOptions, createDict: value as? [AnyHashable:Any] != nil)
                
                try value.encode(to: encoder)
            }
 
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey { fatalError() }
        mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer { fatalError() }
        mutating func superEncoder() -> Encoder { fatalError() }
        mutating func superEncoder(forKey key: K) -> Encoder { fatalError() }
        
        
        private func encode<T: SQLColumnConvertible> (_ value: T, key: K) throws {
            let dataType: SQLData.DataType
            if let options = encoder.userInfo[ CodingUserInfoKey(key) ] as? SQLCodingOptions, let type = options.dataType {
                dataType = type
            } else {
                dataType = T.defaultSQLDataType
            }
            try encode(value.sqlString(for: dataType), keyString: path.keyString(for: key))
        }
        private func encode(_ value: String, keyString: String) throws {
             let data = encoder.data
            
             if data.dictionary[path.tableName] == nil {
                 data.dictionary[path.tableName] = .init()
             }
             if data.dictionary[path.tableName]!.count <= path.row {
                 data.dictionary[path.tableName]!.append(.init())
             }

             data.dictionary[path.tableName]?[path.row][keyString] = value
        }
        private func getReferencing <V: Encodable>(key: K, value: V) throws -> (String, CodingKey, CodingKey)? {
            if let options = encoder.userInfo[.init(key)] as? SQLCodingOptions,
                let ref = options.referenced {
                
                if let sqlValue = value as? SQLCodable {
                    return (type(of: sqlValue).tableName, ref.0, ref.1)
                }
                throw EncodingError.invalidValue(value, .init(codingPath: codingPath, debugDescription: "referenced values must be SQLCodable") )
            }
            return nil
        }
        private func referencingKeyName (key: K, tableName: String, fromCodingKey: CodingKey, toCodingKey: CodingKey) -> String {
            sqlRefKeyPrefix + key.stringValue + sqlKeySeperator + tableName + sqlKeySeperator + fromCodingKey.stringValue
        }
    }
    
}
