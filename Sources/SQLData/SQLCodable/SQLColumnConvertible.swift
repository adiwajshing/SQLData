//
//  File.swift
//
//
//  Created by Adhiraj Singh on 12/29/19.
//

import Foundation

/// SQL Data that only requires one column to represent itself
public protocol SQLColumnConvertible {
    static var defaultSQLDataType: SQLData.DataType { get }
    
    init (sqlValue: String) throws
    func sqlString (for dataType: SQLData.DataType) -> String
}


extension String: SQLColumnConvertible {
    public static var defaultSQLDataType: SQLData.DataType { .string }
    
    public init(sqlValue: String) throws {
        self.init(sqlValue)
    }
    public func sqlString (for dataType: SQLData.DataType) -> String {
        replacingOccurrences(of: "'''", with: "'").replacingOccurrences(of: "''", with: "'").replacingOccurrences(of: "'", with: "''")
    }
}
extension Date: SQLColumnConvertible {
    
    /*public static let sqlDateTimeFormat = "yyyy-MM-dd HH:mm:ss"
    public static let sqlDateFormat = "yyyy-MM-dd"
    public static let sqlTimeFormat = "HH:mm:ss"
    public static let sqlYearFormat = "yyyy"
    
    static func mySQLFormatter (format: String) -> DateFormatter{
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = format
        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateStringFormatter
    }*/
    
    public static var defaultSQLDataType: SQLData.DataType { .timestamp }
    
    public init(sqlValue: String) throws {
        if sqlValue.count == Date.sqlDateTimeFormat.count {
            self.init(string: sqlValue, format: Date.sqlDateTimeFormat)
        } else if sqlValue.count == Date.sqlDateFormat.count, sqlValue.prefix(3).first == "-" {
            self.init(string: sqlValue, format: Date.sqlDateFormat)
        } else if sqlValue.count == Date.sqlTimeFormat.count {
            self.init(string: sqlValue, format: Date.sqlTimeFormat)
        } else if sqlValue.count == Date.sqlYearFormat.count {
            self.init(string: sqlValue, format: Date.sqlYearFormat)
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Date can't be parsed from '\(sqlValue)'"))
        }
    }
    /*public init(string: String, format: String) {
        if let d = Date.mySQLFormatter(format: format).date(from: string) {
            self.init(timeInterval: 0, since: d)
        } else {
            self.init(timeIntervalSince1970: 0)
        }
    }*/
    
    public func sqlString(for dataType: SQLData.DataType) -> String {
        if let format = Date.dateFormat(forDataType: dataType) {
            return Date.mySQLFormatter(format: format).string(from: self)
        }
        return "NULL"
    }
    
    /*public static func dateFormat (forDataType type: SQLData.DataType) -> String? {
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
    }*/
}
extension Data: SQLColumnConvertible {
    
    public static var defaultSQLDataType: SQLData.DataType { .mediumBlob }
    
    public init(sqlValue: String) throws {
        self.init( sqlValue.utf8 )
    }
    public func sqlString(for dataType: SQLData.DataType) -> String { base64EncodedString() }
}
extension UInt64: SQLColumnConvertible {
    
    public static var defaultSQLDataType: SQLData.DataType { .longLong }
    
    public init(sqlValue: String) throws {
        guard let v = Self(sqlValue) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "\(Self.self) can't be parsed from '\(sqlValue)'"))
        }
        self = v
    }
    public func sqlString (for dataType: SQLData.DataType) -> String { String(self) }
}
extension UInt32: SQLColumnConvertible {
    
    public static var defaultSQLDataType: SQLData.DataType { .long }
    
    public init(sqlValue: String) throws {
        guard let v = Self(sqlValue) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "\(Self.self) can't be parsed from '\(sqlValue)'"))
        }
        self = v
    }
    public func sqlString (for dataType: SQLData.DataType) -> String { String(self) }
}
extension UInt16: SQLColumnConvertible {
    
    public static var defaultSQLDataType: SQLData.DataType { .short }
    
    public init(sqlValue: String) throws {
        guard let v = Self(sqlValue) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "\(Self.self) can't be parsed from '\(sqlValue)'"))
        }
        self = v
    }
    public func sqlString (for dataType: SQLData.DataType) -> String { String(self) }
}
extension UInt8: SQLColumnConvertible {
    
    public static var defaultSQLDataType: SQLData.DataType { .tinyInt }
    
    public init(sqlValue: String) throws {
        guard let v = Self(sqlValue) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "\(Self.self) can't be parsed from '\(sqlValue)'"))
        }
        self = v
    }
    public func sqlString (for dataType: SQLData.DataType) -> String { String(self) }
}
extension UInt: SQLColumnConvertible {
    
    public static var defaultSQLDataType: SQLData.DataType { .longLong }
    
    public init(sqlValue: String) throws {
        guard let v = Self(sqlValue) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "\(Self.self) can't be parsed from '\(sqlValue)'"))
        }
        self = v
    }
    public func sqlString (for dataType: SQLData.DataType) -> String { String(self) }
}
extension Int64: SQLColumnConvertible {
    
    public static var defaultSQLDataType: SQLData.DataType { .longLong }
    
    public init(sqlValue: String) throws {
        guard let v = Self(sqlValue) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "\(Self.self) can't be parsed from '\(sqlValue)'"))
        }
        self = v
    }
    public func sqlString (for dataType: SQLData.DataType) -> String { String(self) }
}
extension Int32: SQLColumnConvertible {
    
    public static var defaultSQLDataType: SQLData.DataType { .long }
    
    public init(sqlValue: String) throws {
        guard let v = Self(sqlValue) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "\(Self.self) can't be parsed from '\(sqlValue)'"))
        }
        self = v
    }
    public func sqlString (for dataType: SQLData.DataType) -> String { String(self) }
}
extension Int16: SQLColumnConvertible {
    
    public static var defaultSQLDataType: SQLData.DataType { .short }
    
    public init(sqlValue: String) throws {
        guard let v = Self(sqlValue) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "\(Self.self) can't be parsed from '\(sqlValue)'"))
        }
        self = v
    }
    public func sqlString (for dataType: SQLData.DataType) -> String { String(self) }
}
extension Int8: SQLColumnConvertible {
    
    public static var defaultSQLDataType: SQLData.DataType { .tinyInt }
    
    public init(sqlValue: String) throws {
        guard let v = Self(sqlValue) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "\(Self.self) can't be parsed from '\(sqlValue)'"))
        }
        self = v
    }
    public func sqlString (for dataType: SQLData.DataType) -> String { String(self) }
}
extension Int: SQLColumnConvertible {
    
    public static var defaultSQLDataType: SQLData.DataType { .longLong }
    
    public init(sqlValue: String) throws {
        guard let v = Self(sqlValue) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "\(Self.self) can't be parsed from '\(sqlValue)'"))
        }
        self = v
    }
    public func sqlString (for dataType: SQLData.DataType) -> String { String(self) }
}
extension Double: SQLColumnConvertible {
    
    public static var defaultSQLDataType: SQLData.DataType { .double }
    
    public init(sqlValue: String) throws {
        guard let v = Self(sqlValue) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "\(Self.self) can't be parsed from '\(sqlValue)'"))
        }
        self = v
    }
    public func sqlString (for dataType: SQLData.DataType) -> String { String(self) }
}
extension Float: SQLColumnConvertible {
    
    public static var defaultSQLDataType: SQLData.DataType { .float }
    
    public init(sqlValue: String) throws {
        guard let v = Self(sqlValue) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "\(Self.self) can't be parsed from '\(sqlValue)'"))
        }
        self = v
    }
    public func sqlString (for dataType: SQLData.DataType) -> String { String(self) }
}
extension Bool: SQLColumnConvertible {
    
    public static var defaultSQLDataType: SQLData.DataType { .tinyInt }
    
    public init(sqlValue: String) throws {
        self = (sqlValue == "1" || sqlValue.lowercased() == "true")
    }
    
    public func sqlString (for dataType: SQLData.DataType) -> String { self ? "1" : "0" }
}

