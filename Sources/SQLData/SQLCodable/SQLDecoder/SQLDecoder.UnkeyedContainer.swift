//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 1/21/20.
//

import Foundation

extension SQLDecoder {
    
    struct SQLUnkeyedContainer: UnkeyedDecodingContainer {
        let tableName: String
        let data: SQLEncodedData
        
        let indices: [(Int, String)]
        
        let codingPath: [CodingKey]
        
        var currentIndex: Int = 0
        var count: Int? { indices.count }
        var isAtEnd: Bool { currentIndex >= (count ?? 0) }
        
        init (path: DataPath, data: SQLEncodedData, codingPath: [CodingKey]) throws {
            let selfTableName = path.tableName + sqlKeySeperator + path.key
            
            self.tableName = selfTableName
            self.data = data
            self.codingPath = codingPath
            
            let indices = try getIndices(tableName: path.tableName, selfTableName: selfTableName, data: data, valueIndex: path.row)
            if indices.count > 0 {
                let isDictionary = sqlIsDictionary(dict: data.dictionary[selfTableName]!.first!)
                
                if isDictionary {
                    self.indices = indices.flatMap {
                        [($0, sqlDictionaryKeyReferencingKey), ($0, sqlSingleValueReferencingKey)]
                    }
                } else {
                    self.indices = indices.map { ($0, sqlSingleValueReferencingKey) }
                }
            } else {
                self.indices = []
            }
            
        }
        
        mutating func decodeNil() throws -> Bool {
            fatalError()
        }
        
        mutating func decode(_ type: Bool.Type) throws -> Bool { try decodeItem(type) }
        mutating func decode(_ type: String.Type) throws -> String { try decodeItem(type) }
        mutating func decode(_ type: Double.Type) throws -> Double { try decodeItem(type) }
        mutating func decode(_ type: Float.Type) throws -> Float { try decodeItem(type) }
        
        mutating func decode(_ type: Int.Type) throws -> Int { try decodeItem(type) }
        mutating func decode(_ type: Int8.Type) throws -> Int8 { try decodeItem(type) }
        mutating func decode(_ type: Int16.Type) throws -> Int16 { try decodeItem(type) }
        mutating func decode(_ type: Int32.Type) throws -> Int32 { try decodeItem(type) }
        mutating func decode(_ type: Int64.Type) throws -> Int64 { try decodeItem(type) }
        
        mutating func decode(_ type: UInt.Type) throws -> UInt { try decodeItem(type) }
        mutating func decode(_ type: UInt8.Type) throws -> UInt8 { try decodeItem(type) }
        mutating func decode(_ type: UInt16.Type) throws -> UInt16 { try decodeItem(type) }
        mutating func decode(_ type: UInt32.Type) throws -> UInt32 { try decodeItem(type) }
        mutating func decode(_ type: UInt64.Type) throws -> UInt64 { try decodeItem(type) }
        
        mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            let decoder = SQLDecoder(path: .init(tableName: tableName, key: indices[currentIndex].1, row: indices[currentIndex].0), data: data, codingPath: codingPath)
            currentIndex += 1
            return try T(from: decoder)
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            fatalError()
        }
        
        mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            fatalError()
        }
        
        mutating func superDecoder() throws -> Decoder {
            fatalError()
        }
        
        private mutating func decodeItem<T: SQLColumnConvertible> (_ t: T.Type) throws -> T {
            let dict = data.dictionary[tableName]![ indices[currentIndex].0 ]
            
            guard let value = dict[ indices[currentIndex].1 ] else {
                throw DecodingError.valueNotFound(t, .init(codingPath: codingPath, debugDescription: "Single value unexpectedly nil at \(indices[currentIndex])") )
            }
            currentIndex += 1
            return try T(sqlValue: value)
        }
    }
    
}
extension SQLDecoder {
    
    class SQLDictionaryContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
        typealias Key = K
       
        let codingPath: [CodingKey]
        let allKeys: [K]
        let indices: [Int]
        var curIndex = 0
       
        let tableName: String
        let data: SQLEncodedData
       
        init (path: DataPath, data: SQLEncodedData, codingPath: [CodingKey]) throws {
            
            let selfTableName = path.tableName + sqlKeySeperator + path.key
            
            self.tableName = selfTableName
            self.data = data
            self.codingPath = codingPath
            self.indices = try getIndices(tableName: path.tableName, selfTableName: selfTableName, data: data, valueIndex: path.row)
            
            self.allKeys = indices.map { K(stringValue: data.dictionary[selfTableName]![$0]["key"]!)! }
        }
        
        func contains(_ key: K) -> Bool { true }
        func decodeNil(forKey key: K) throws -> Bool { false }
        
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
            
            let index = indices[curIndex]
            let decoder = SQLDecoder(path: .init(tableName: tableName, key: sqlSingleValueReferencingKey, row: index), data: data, codingPath: codingPath)
            curIndex += 1
            return try T(from: decoder)
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey { fatalError() }
        func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer { fatalError() }
        func superDecoder() throws -> Decoder { fatalError() }
        func superDecoder(forKey key: K) throws -> Decoder { fatalError() }
        
        private func decode<T: SQLColumnConvertible> (_ t: T.Type, key: CodingKey) throws -> T {
             guard let stringValue = try table()[ sqlSingleValueReferencingKey ] else {
                 var codingPath = self.codingPath
                 codingPath.append(key)
                 throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: "KEY NOT PRESENT") )
             }
            curIndex += 1
            return try T(sqlValue: stringValue)
        }
        private func table () throws -> [String:String] {
            guard let dict = data.dictionary[tableName]?[curIndex] else {
                throw DecodingError.dataCorrupted( .init(codingPath: codingPath, debugDescription: "TABLE NOT FOUND") )
            }
            return dict
        }
       
    }
}

internal func getIndices (tableName: String, selfTableName: String, data: SQLEncodedData, valueIndex: Int) throws -> [Int] {
    if let dict = data.dictionary[tableName]?[valueIndex],
        let dict2 = data.dictionary[selfTableName]?.first {
        let ogTablePrefix = tableName + sqlKeySeperator
       // print(ogTablePrefix )
        guard let refKey = dict2.first(where: { $0.0.hasPrefix(ogTablePrefix) })?.key else {
            throw DecodingError.dataCorrupted( .init(codingPath: [], debugDescription: "Reference key not present for \(tableName)") )
        }
        let refValue = dict[refKey.replacingOccurrences(of: ogTablePrefix, with: "")]!
        return data.dictionary[selfTableName]!.indices.filter {
            data.dictionary[selfTableName]![$0][refKey] == refValue
        }
    } else {
        throw DecodingError.dataCorrupted( .init(codingPath: [], debugDescription: "Required tables not present: \(tableName), \(selfTableName)") )
    }
}

func sqlIsDictionary (dict: [String: String]) -> Bool {
    dict.contains(where:
    {
        $0.key == sqlDictionaryKeyReferencingKey || $0.key.hasPrefix(sqlDictionaryKeyReferencingKey + sqlKeySeperator)
    })
}
