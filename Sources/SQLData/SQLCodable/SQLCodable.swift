//
//  SQLCodable.swift
//  
//
//  Created by Adhiraj Singh on 1/23/20.
//

import Foundation

public protocol SQLCodable: Codable {
    static var tableName: String { get }
    static var options: [CodingUserInfoKey:SQLCodingOptions] { get }
}
public extension SQLCodable {
    static var tableName: String { String(describing: Self.self) }
}
public struct SQLCodingOptions {
    let flags: SQLData.FieldFlag?
    let dataType: SQLData.DataType?
    let referenced: (CodingKey, CodingKey)?
    
    static func options (flags: SQLData.FieldFlag? = nil, dataType: SQLData.DataType? = nil, referenced: (CodingKey, CodingKey)? = nil) -> SQLCodingOptions {
        SQLCodingOptions(flags: flags, dataType: dataType, referenced: referenced)
    }
    
}
public extension CodingUserInfoKey {
    
    init <S: CodingKey> (_ codingKey: S) { self.init(rawValue: codingKey.stringValue)! }
    
}
