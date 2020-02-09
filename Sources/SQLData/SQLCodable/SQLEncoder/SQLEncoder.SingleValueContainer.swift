//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 1/23/20.
//

import Foundation

extension SQLEncoder {
    
    struct SingleValueContainer: SingleValueEncodingContainer {
        let codingPath: [CodingKey]
        let encoder: SQLEncoder
        let path: DataPath
        
        mutating func encodeNil() throws { try encode(strValue: sqlNullValue) }
        
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
            let enc = SQLEncoder(T.self, path: path, data: encoder.data, codingPath: codingPath)
            try value.encode(to: enc)
        }
        private func encode<T: SQLColumnConvertible> (value: T) throws {
            let dataType = (encoder.userInfo[ .primaryKey ] as? SQLCodingOptions)?.dataType ?? T.defaultSQLDataType
            let strValue = value.sqlString(for: dataType)
            
            try encode(strValue: strValue)
        }
        private func encode(strValue: String) throws {
            let data = encoder.data
            
            if data.dictionary[path.tableName] == nil {
                data.dictionary[path.tableName] = .init()
            }
            if data.dictionary[path.tableName]!.count <= path.row {
                data.dictionary[path.tableName]!.append(.init())
            }
            
            data.dictionary[path.tableName]![path.row][path.key] = strValue
        }
    }
}

