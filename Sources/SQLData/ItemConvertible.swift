//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 12/29/19.
//

import Foundation

/// SQL Data that only requires one column to represent itself
public protocol SQLItemConvertible: SQLDataConvertible {
    
    static var defaultDataType: SQLData.DataType { get }
    
    init? (sqlValue: String, type: SQLData.DataType, flags: SQLData.FieldFlag)
    
    func stringValue (for dataType: SQLData.DataType) -> String
}
public extension SQLItemConvertible {
    
    static var primaryKeyPath: SQLData.KeyPathDataColumn? { return nil }
    static var mainKeyPaths: [SQLData.KeyPathDataColumn] { return [ SQLData.KeyPathDataColumn(item: \Self.self, name: "value", flags: []) ] }
    static var subKeyPaths: [SQLData.KeyPathArrayColumn] { return [] }
    
    internal static func write<K: SQLDataConvertible>(keyPath: AnyKeyPath, object: inout K, stringValue: String?, column: SQLData.Column) -> Bool {
        
        if let path = keyPath as? WritableKeyPath<K, Self> {
            if let stringValue = stringValue, let value = Self.init(sqlValue: stringValue, type: column.dataType, flags: column.flags) {
                object[keyPath: path] = value
            } else {
                return false
            }
            
        } else {
            let path = keyPath as! WritableKeyPath<K, Self?>
            if let stringValue = stringValue {
                object[keyPath: path] = Self.init(sqlValue: stringValue, type: column.dataType, flags: column.flags)!
            } else {
                object[keyPath: path] = nil
            }
        }
        return true
    }
    /*internal static func write<K: SQLDataConvertible>(keyPath: AnyKeyPath, objectFrom: K, objectTo: inout K) {
        if let path = keyPath as? WritableKeyPath<K, Self> {
            objectTo[keyPath: path] = objectFrom[keyPath: path]
        } else if let path = keyPath as? WritableKeyPath<K, Self?> {
            objectTo[keyPath: path] = objectFrom[keyPath: path]
        }
    }*/
}

public protocol SQLEnumConvertible: SQLItemConvertible, RawRepresentable where RawValue: SQLItemConvertible { }
public extension SQLEnumConvertible {
    
    static var defaultDataType: SQLData.DataType {
        return RawValue.defaultDataType
    }
    init() {
        self.init(rawValue: RawValue.init())!
    }
    init?(sqlValue: String, type: SQLData.DataType, flags: SQLData.FieldFlag) {
        if let value = RawValue.init(sqlValue: sqlValue, type: type, flags: flags) {
            self.init(rawValue: value)
        } else {
            return nil
        }
    }
    func stringValue(for dataType: SQLData.DataType) -> String {
        return rawValue.stringValue(for: dataType)
    }
    
}

extension String: SQLItemConvertible {    
    
    public static var defaultDataType: SQLData.DataType { return .string }
    
    public init?(sqlValue: String, type: SQLData.DataType, flags: SQLData.FieldFlag) {
        self.init()
        self.append(contentsOf: sqlValue)
    }
    
    public func stringValue (for dataType: SQLData.DataType) -> String {
        let str = self.replacingOccurrences(of: "'''", with: "'").replacingOccurrences(of: "''", with: "'").replacingOccurrences(of: "'", with: "''")
        return "'\(str)'"
    }
}
extension Date: SQLItemConvertible {
    
    public static let sqlDateTimeFormat = "yyyy-MM-dd HH:mm:ss"
    public static let sqlDateFormat = "yyyy-MM-dd"
    public static let sqlTimeFormat = "HH:mm:ss"
    public static let sqlYearFormat = "yyyy"
    
    static func mySQLFormatter (format: String) -> DateFormatter{
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = format
        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateStringFormatter
    }
    
    public static var defaultDataType: SQLData.DataType { return .timestamp }
    
    public init?(sqlValue: String, type: SQLData.DataType, flags: SQLData.FieldFlag) {
        if let format = Date.dateFormat(forDataType: type) {
            self.init(string: sqlValue, format: format)
        } else {
            return nil
        }
    }
    public init(string: String, format: String) {
        if let d = Date.mySQLFormatter(format: format).date(from: string) {
            self.init(timeInterval: 0, since: d)
        } else {
            self.init(timeIntervalSince1970: 0)
        }
    }
    
    public func stringValue(for dataType: SQLData.DataType) -> String {
        if let format = Date.dateFormat(forDataType: dataType) {
            return "'" + Date.mySQLFormatter(format: format).string(from: self) + "'"
        }
        return "NULL"
    }
    
    public static func dateFormat (forDataType type: SQLData.DataType) -> String? {
        switch type {
        case .dateTime, .timestamp:
            return Date.sqlDateTimeFormat
        case .time:
            return Date.sqlTimeFormat
        case .date:
            return Date.sqlDateFormat
        case .year:
            return Date.sqlYearFormat
        default:
            return nil
        }
    }
}
extension Data: SQLItemConvertible {
    
    public static var defaultDataType: SQLData.DataType { return .mediumBlob }
    
    public init?(sqlValue: String, type: SQLData.DataType, flags: SQLData.FieldFlag) {
        self.init( sqlValue.utf8 )
    }
    
    public func stringValue(for dataType: SQLData.DataType) -> String { return self.base64EncodedString() }
}
extension UInt64: SQLItemConvertible {
    
    public static var defaultDataType: SQLData.DataType { return .longLong }
    
    public init?(sqlValue: String, type: SQLData.DataType, flags: SQLData.FieldFlag) {
        self.init(sqlValue)
    }
    public func stringValue (for dataType: SQLData.DataType) -> String { return "'\(self)'" }
}
extension UInt32: SQLItemConvertible {
    
    public static var defaultDataType: SQLData.DataType { return .long }
    
    public init?(sqlValue: String, type: SQLData.DataType, flags: SQLData.FieldFlag) {
        self.init(sqlValue)
    }
    
    public func stringValue (for dataType: SQLData.DataType) -> String { return "'\(self)'" }
}
extension UInt16: SQLItemConvertible {
    
    public static var defaultDataType: SQLData.DataType { return .short }
    
    public init?(sqlValue: String, type: SQLData.DataType, flags: SQLData.FieldFlag) {
        self.init(sqlValue)
    }
    
    public func stringValue (for dataType: SQLData.DataType) -> String { return "'\(self)'" }
}
extension UInt8: SQLItemConvertible {
    
    public static var defaultDataType: SQLData.DataType { return .tinyInt }
    
    public init?(sqlValue: String, type: SQLData.DataType, flags: SQLData.FieldFlag) {
        self.init(sqlValue)
    }
    
    public func stringValue (for dataType: SQLData.DataType) -> String { return "'\(self)'" }
}
extension UInt: SQLItemConvertible {
    
    public static var defaultDataType: SQLData.DataType { return .long }
    
    public init?(sqlValue: String, type: SQLData.DataType, flags: SQLData.FieldFlag) {
        self.init(sqlValue)
    }
    
    public func stringValue (for dataType: SQLData.DataType) -> String { return "'\(self)'" }
}
extension Int64: SQLItemConvertible {
    
    public static var defaultDataType: SQLData.DataType { return .longLong }
    
    public init?(sqlValue: String, type: SQLData.DataType, flags: SQLData.FieldFlag) {
        self.init(sqlValue)
    }
    
    public func stringValue (for dataType: SQLData.DataType) -> String { return "'\(self)'" }
}
extension Int: SQLItemConvertible {
    
    public static var defaultDataType: SQLData.DataType { return .longLong }
    
    public init?(sqlValue: String, type: SQLData.DataType, flags: SQLData.FieldFlag) {
        self.init(sqlValue)
    }
    
    public func stringValue (for dataType: SQLData.DataType) -> String { return "'\(self)'" }
}
extension Int32: SQLItemConvertible {
    
    public static var defaultDataType: SQLData.DataType { return .long }
    
    public init?(sqlValue: String, type: SQLData.DataType, flags: SQLData.FieldFlag) {
        self.init(sqlValue)
    }
    
    public func stringValue (for dataType: SQLData.DataType) -> String { return "'\(self)'" }
}
extension Int16: SQLItemConvertible {
    
    public static var defaultDataType: SQLData.DataType { return .short }
    
    public init?(sqlValue: String, type: SQLData.DataType, flags: SQLData.FieldFlag) {
        self.init(sqlValue)
    }
    
    public func stringValue (for dataType: SQLData.DataType) -> String { return "'\(self)'" }
}
extension Int8: SQLItemConvertible {
    
    public static var defaultDataType: SQLData.DataType { return .tinyInt }
    
    public init?(sqlValue: String, type: SQLData.DataType, flags: SQLData.FieldFlag) {
        self.init(sqlValue)
    }
    
    public func stringValue (for dataType: SQLData.DataType) -> String { return "'\(self)'" }
}
extension Double: SQLItemConvertible {
    
    public static var defaultDataType: SQLData.DataType { return .double }
    
    public init?(sqlValue: String, type: SQLData.DataType, flags: SQLData.FieldFlag) {
        self.init(sqlValue)
    }
    
    public func stringValue (for dataType: SQLData.DataType) -> String { return "'\(self)'" }
}
extension Float32: SQLItemConvertible {
    
    public static var defaultDataType: SQLData.DataType { return .float }
    
    public init?(sqlValue: String, type: SQLData.DataType, flags: SQLData.FieldFlag) {
        self.init(sqlValue)
    }
    
    public func stringValue (for dataType: SQLData.DataType) -> String { return "'\(self)'" }
}
extension Bool: SQLItemConvertible {
    
    public static var defaultDataType: SQLData.DataType { return .tinyInt }
    
    public init?(sqlValue: String, type: SQLData.DataType, flags: SQLData.FieldFlag) {
        self.init(sqlValue == "1" || sqlValue.lowercased() == "true")
    }
    
    public func stringValue (for dataType: SQLData.DataType) -> String { return self ? "1" : "0" }
}

