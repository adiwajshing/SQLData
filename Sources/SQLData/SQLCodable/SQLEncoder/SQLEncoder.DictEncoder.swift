//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 1/23/20.
//

import Foundation


extension SQLEncoder {
    
    struct DictKeyedContainer<K: CodingKey>: KeyedEncodingContainerProtocol {
        typealias Key = K
        
        let codingPath: [CodingKey]
        let tableName: String
        let encoder: SQLEncoder
        let refKey: (String, String)?
        
        init (codingPath: [CodingKey], path: DataPath, encoder: SQLEncoder) {
            self.codingPath = codingPath
            self.encoder = encoder
            self.tableName = path.key.isEmpty ? path.tableName : path.tableName + sqlKeySeperator + path.key
            self.refKey = encoder.userInfo[.refPrimaryKey] as? (String, String)
        }
        
        mutating func encodeNil(forKey key: K) throws {
            fatalError()
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
            let data = encoder.data
            
            if data.dictionary[tableName] == nil {
                data.dictionary[tableName] = .init()
            }
            
            data.dictionary[tableName]!.append(.init())
            
            let path = DataPath(tableName: tableName, key: "value", row: data.dictionary[tableName]!.count-1)
            let encoder = SQLEncoder(T.self, path: path, data: self.encoder.data, codingPath: codingPath)
            try value.encode(to: encoder)
            
            if let refKey = refKey {
                data.dictionary[tableName]![path.row][ sqlDictionaryKeyReferencingKey ] = key.stringValue
                data.dictionary[tableName]![path.row][refKey.0] = refKey.1
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
            try encode(value.sqlString(for: dataType), keyString: key.stringValue)
        }
        private func encode(_ value: String, keyString: String) throws {
            let data = encoder.data
            
            if data.dictionary[tableName] == nil {
                data.dictionary[tableName] = .init()
            }
            
            var dict = [sqlSingleValueReferencingKey: value]
            if let refKey = refKey {
                dict[refKey.0] = refKey.1
            } else {
                throw EncodingError.invalidValue(value, .init(codingPath: codingPath, debugDescription: "Primary key from referencing table required to store single value array"))
            }
            
            data.dictionary[tableName]!.append(dict)
        }
    }
    
}
