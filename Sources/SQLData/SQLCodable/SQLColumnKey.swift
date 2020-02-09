//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 1/8/20.
//

import Foundation

public struct SQLItemColumn {
    public let dataType: SQLData.DataType
    public let flags: SQLData.FieldFlag
    
    public init (dataType: SQLData.DataType, flags: SQLData.FieldFlag) {
       // self.key = key
        self.dataType = dataType
        self.flags = flags
    }
}
/*public protocol SQLCodingOptions {
    var key: CodingKey { get }
}
public extension SQLData {
    
    struct ItemColumn: SQLCodingOptions {
        public let key: CodingKey
        
        public let dataType: DataType
        public let flags: FieldFlag
        
        public init (_ key: CodingKey, dataType: DataType, flags: FieldFlag) {
            self.key = key
            self.dataType = dataType
            self.flags = flags
        }
    }
    struct ReferencedColumn: SQLCodingOptions {
        public let key: CodingKey
        public let type: SQLCodable.Type
        
        public init<K: SQLCodable, V: SQLItemConvertible>(_ key: CodingKey, on: KeyPath<K, V>) {
            self.key = key
            self.type = K.self
        }
    }
}

*/
