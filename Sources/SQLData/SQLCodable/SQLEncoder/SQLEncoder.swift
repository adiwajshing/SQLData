//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 1/23/20.
//

import Foundation

extension CodingUserInfoKey {
    static let primaryKey = CodingUserInfoKey(rawValue: "table_primary_key")!
    static let refPrimaryKey = CodingUserInfoKey(rawValue: "table_ref_primary_key")!
}

open class SQLEncoder: Encoder {

    public var codingPath: [CodingKey]
    public var userInfo: [CodingUserInfoKey : Any]
    
    var path: DataPath
    var data: SQLEncodedData
    var createDict: Bool
    
    public convenience init <S: SQLCodable> (_ type: S.Type) {
        self.init(type, path: DataPath(tableName: S.tableName, key: "", row: 0), data: .init(), codingPath: [])
    }
    
    init <S: Encodable> (_ type: S.Type, path: DataPath, data: SQLEncodedData, codingPath: [CodingKey], additionalOptions: [CodingUserInfoKey:Any] = [:], createDict: Bool = false) {
        self.codingPath = codingPath
        self.path = path
        
        let op = (S.self as? SQLCodable.Type)?.options ?? [:]
        var options = op as [CodingUserInfoKey:Any]
        if let str = op.first(where: {
            $0.value.flags?.contains(.primaryKey) ?? false
        })?.key.rawValue {
            options[.primaryKey] = str
        }
        
        options.merge(additionalOptions, uniquingKeysWith: { (s0, s1) in s0 })
        
        self.userInfo = options
        self.createDict = createDict
        self.data = data
    }
    
    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        if createDict {
            return .init ( DictKeyedContainer(codingPath: codingPath, path: path, encoder: self) )
        }
        return .init ( KeyedContainer(codingPath: codingPath, path: path, encoder: self) )
        
    }
    
    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        UnkeyedContainer(codingPath: codingPath, path: path, encoder: self, isDict: createDict)
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        SingleValueContainer(codingPath: codingPath, encoder: self, path: path)
    }

}
