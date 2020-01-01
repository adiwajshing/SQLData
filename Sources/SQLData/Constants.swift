//
//  Constants.swift
// static let MYsql_driver
//
//  Created by Marius Corega on 18/12/15.
//  Copyright © 2015 Marius Corega. All rights reserved.
//

extension SQLData {
    
    public struct FieldFlag: OptionSet, CustomStringConvertible {
        
        public let rawValue: UInt16
        
        public static let notNull = FieldFlag( rawValue: 0x0001 )
        public static let primaryKey = FieldFlag( rawValue: 0x0002 )
        public static let unique = FieldFlag( rawValue: 0x0004 )
        public static let multipleKeys = FieldFlag( rawValue: 0x0008 )
        public static let blob = FieldFlag( rawValue: 0x0010 )
        public static let unsigned = FieldFlag( rawValue: 0x0020 )
        public static let zeroFill = FieldFlag( rawValue: 0x0040 )
        public static let binary = FieldFlag( rawValue: 0x0080 )
        public static let enumeration = FieldFlag( rawValue: 0x0100 )
        public static let autoIncrement = FieldFlag( rawValue: 0x0200 )
        public static let timestamp = FieldFlag( rawValue: 0x0400 )
        public static let set = FieldFlag( rawValue: 0x0800 )
        
        public var description: String {
            
            var arr = [String]()
            
            if self.contains(.unsigned) {
                arr.append("UNSIGNED")
            }
            if self.contains(.primaryKey) {
                arr.append("PRIMARY KEY")
            }
            if self.contains(.unique) {
                arr.append("UNIQUE")
            }
            if self.contains(FieldFlag.autoIncrement) {
                arr.append("AUTOINCREMENT")
            }
            if self.contains(.notNull) {
                arr.append("NOT NULL")
            }
            if self.contains(.binary) {
                arr.append("BINARY")
            }
            
            return arr.joined(separator: " ")
        }
        public init( rawValue: UInt16 ) {
            self.rawValue = rawValue
        }
    }
    
    public enum DataType: UInt8 {
        case unknown = 0xaa //unknown type
        case decimal = 0x00
        case tinyInt = 0x01  // int8, uint8, bool
        case short = 0x02 // int16, uint16
        case long = 0x03 // int32, uint32
        case float = 0x04 // float32
        case double = 0x05 // float64
        case null = 0x06
        case timestamp = 0x07
        case longLong = 0x08 // int64, uint64
        case int24 = 0x09
        case date = 0x0a
        case time = 0x0b
        case dateTime = 0x0c
        case year = 0x0d
        case newDate = 0x0e
        case varChar = 0x0f
        case bit = 0x10
        case newDecimal = 0xf6
        case enumeration = 0xf7
        case set = 0xf8
        case tinyBlob = 0xf9
        case mediumBlob = 0xfa
        case longBlob = 0xfb
        case blob = 0xfc
        case varString = 0xfd
        case string = 0xfe
        case geometry = 0xff
        
        public var description: String {
            return "\(self)".uppercased()
        }
    }
    
}

