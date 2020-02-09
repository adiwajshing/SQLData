//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 1/21/20.
//

import Foundation

extension SQLDecoder {
    
    struct SQLSingleValueDecoder: SingleValueDecodingContainer {
        
        let path: DataPath
        let data: SQLEncodedData
        let codingPath: [CodingKey]
        
        func decodeNil() -> Bool {
            let value = stringValue()
            return value == nil || value == sqlNullValue
        }
        
        func decode(_ type: Bool.Type) throws -> Bool { try decodeItem(type) }
        func decode(_ type: String.Type) throws -> String { try decodeItem(type) }
        
        func decode(_ type: Double.Type) throws -> Double { try decodeItem(type) }
        func decode(_ type: Float.Type) throws -> Float { try decodeItem(type) }
        
        func decode(_ type: Int.Type) throws -> Int { try decodeItem(type) }
        func decode(_ type: Int8.Type) throws -> Int8 { try decodeItem(type) }
        func decode(_ type: Int16.Type) throws -> Int16 { try decodeItem(type) }
        func decode(_ type: Int32.Type) throws -> Int32 { try decodeItem(type) }
        func decode(_ type: Int64.Type) throws -> Int64 { try decodeItem(type) }
        
        func decode(_ type: UInt.Type) throws -> UInt { try decodeItem(type) }
        func decode(_ type: UInt8.Type) throws -> UInt8 { try decodeItem(type) }
        func decode(_ type: UInt16.Type) throws -> UInt16 { try decodeItem(type) }
        func decode(_ type: UInt32.Type) throws -> UInt32 { try decodeItem(type) }
        func decode(_ type: UInt64.Type) throws -> UInt64 { try decodeItem(type) }
        
        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            let decoder = SQLDecoder(path: path, data: data, codingPath: codingPath)
            return try T(from: decoder)
        }
        
        private func decodeItem<T: SQLColumnConvertible> (_ type: T.Type) throws -> T {
            
            if let stringValue = stringValue(), stringValue != sqlNullValue {
                return try T(sqlValue: stringValue)
            } else {
                throw DecodingError.valueNotFound(type, .init(codingPath: codingPath, debugDescription: "SINGLE VALUE NOT PRESENT"))
            }
        }
        private func stringValue () -> String? {
            data.dictionary[path.tableName]?[path.row][path.key]
        }
    }
    
}
