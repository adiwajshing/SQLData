//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 1/23/20.
//

import Foundation

extension SQLEncoder {
    
    struct UnkeyedContainer: UnkeyedEncodingContainer {
        
        let codingPath: [CodingKey]
        let tableName: String
        let encoder: SQLEncoder
        let refKey: (String, String)?
        let isDict: Bool
        
        var count: Int = 0
        
        init (codingPath: [CodingKey], path: DataPath, encoder: SQLEncoder, isDict: Bool) {
            self.codingPath = codingPath
            self.encoder = encoder
            self.tableName = path.key.isEmpty ? path.tableName : path.tableName + sqlKeySeperator + path.key
            self.refKey = encoder.userInfo[.refPrimaryKey] as? (String, String)
            self.isDict = isDict
           // print("\(path), \(isDict)")
        }
        
        mutating func encodeNil() throws {
            fatalError()
        }
        
        mutating func encode(_ value: Bool) throws { try encode(value: value) }
        mutating func encode(_ value: String) throws { try encode(value: value) }
        
        mutating func encode(_ value: Double) throws { try encode(value: value) }
        mutating func encode(_ value: Float) throws { try encode(value: value) }
        
        mutating func encode(_ value: Int) throws { try encode(value: value) }
        mutating func encode(_ value: Int8) throws { try encode(value: value) }
        mutating func encode(_ value: Int16) throws { try encode(value: value) }
        mutating func encode(_ value: Int32) throws { try encode(value: value) }
        mutating func encode(_ value: Int64) throws { try encode(value: value) }
        
        mutating func encode(_ value: UInt) throws { try encode(value: value) }
        mutating func encode(_ value: UInt8) throws { try encode(value: value) }
        mutating func encode(_ value: UInt16) throws { try encode(value: value) }
        mutating func encode(_ value: UInt32) throws { try encode(value: value) }
        
        mutating func encode(_ value: UInt64) throws { try encode(value: value) }
        
        mutating func encode<T>(_ value: T) throws where T : Encodable {
            
            let data = encoder.data
            
            if (isDict && count % 2 == 0) || !isDict {
                if data.dictionary[tableName] == nil {
                    data.dictionary[tableName] = .init()
                }
                data.dictionary[tableName]!.append(.init())
            }
            let k = isDict ? count % 2 == 0 ? sqlDictionaryKeyReferencingKey : sqlSingleValueReferencingKey : sqlSingleValueReferencingKey
            
            let path = DataPath(tableName: tableName, key: k, row: data.dictionary[tableName]!.count-1)
            let encoder = SQLEncoder(T.self, path: path, data: self.encoder.data, codingPath: codingPath)
            try value.encode(to: encoder)
            
            if let refKey = refKey {
                data.dictionary[tableName]![path.row][refKey.0] = refKey.1
            } else {
                throw EncodingError.invalidValue(value, .init(codingPath: codingPath, debugDescription: "Primary key from referencing table required to store single value array"))
            }
            count += 1
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey { fatalError() }
        mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer { fatalError() }
        mutating func superEncoder() -> Encoder { fatalError() }
        
        private mutating func encode<T: SQLColumnConvertible> (value: T) throws {
            let strValue = value.sqlString(for: T.defaultSQLDataType)
            let k = isDict ? count % 2 == 0 ? sqlDictionaryKeyReferencingKey : sqlSingleValueReferencingKey : sqlSingleValueReferencingKey
            try encode(strValue, keyString: k)
        }
        private mutating func encode(_ value: String, keyString: String) throws {
            let data = encoder.data
            
            if (isDict && count % 2 == 0) || !isDict {
                if data.dictionary[tableName] == nil {
                    data.dictionary[tableName] = .init()
                }
                data.dictionary[tableName]!.append(.init())
            }
            var dict = [keyString: value]
            if let refKey = refKey {
                dict[refKey.0] = refKey.1
            } else {
                throw EncodingError.invalidValue(value, .init(codingPath: codingPath, debugDescription: "Primary key from referencing table required to store single value array"))
            }
            data.dictionary[tableName]![data.dictionary[tableName]!.count-1] = dict
            count += 1
        }
        
    }
}
