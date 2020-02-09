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
            if self.contains(.autoIncrement) {
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
    
    public enum DataType: Hashable {
        case unknown //unknown type
        case decimal
        case tinyInt  // int8, uint8, bool
        case short // int16, uint16
        case long // int32, uint32
        case float // float32
        case double // float64
        case null
        case timestamp
        case longLong // int64, uint64
        case int24
        case date
        case time
        case dateTime
        case year
        case newDate
        case varChar (Int)
        case bit
        case newDecimal
        case enumeration
        case set
        case tinyBlob
        case mediumBlob
        case longBlob
        case blob(Int)
        case varString
        case string
        case geometry
        case char(Int)
        
        public var description: String { "\(self)".uppercased() }
    }
    
}

