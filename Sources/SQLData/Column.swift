//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 12/29/19.
//

import Foundation

public extension SQLData {
    
    struct Column: CustomStringConvertible {
        
        public let name: String
        public let dataType: DataType
        public let flags: FieldFlag
        
        public var description: String {
            return "'\(name)' \(dataType.description) \(flags)"
        }
        
        public init (name: String, dataType: DataType, flags: FieldFlag) {
            self.name = name
            self.dataType = dataType
            self.flags = flags
        }
        
        func with (flags: FieldFlag) -> Column {
            return Column(name: name, dataType: dataType, flags: flags)
        }
        func with (name: String) -> Column {
            return Column(name: name, dataType: dataType, flags: flags)
        }
        
    }
    
}

public func == (lhs: SQLData.Column, rhs: SQLData.Column) -> Bool {
    return lhs.name == rhs.name && lhs.dataType == rhs.dataType && lhs.flags == rhs.flags
}
extension SQLData.Column: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(dataType)
        hasher.combine(flags.rawValue)
    }
    
    public init <T: SQLItemConvertible>(name: String, fromType type: T.Type, flags: SQLData.FieldFlag) {
        
        var extraFlags: SQLData.FieldFlag = [.notNull]
        if type.self is UInt64.Type || type.self is UInt32.Type || type.self is UInt16.Type || type.self is UInt8.Type {
            extraFlags.formUnion(.unsigned)
        }
        
        self.init(name: name, dataType: T.defaultDataType, flags: flags.union(extraFlags))
    }
    public init <T: SQLItemConvertible>(name: String, fromType type: Optional<T>.Type, flags: SQLData.FieldFlag) {
        
        var extraFlags: SQLData.FieldFlag = []
        if type.self is UInt64.Type || type.self is UInt32.Type || type.self is UInt16.Type || type.self is UInt8.Type {
            extraFlags.formUnion(.unsigned)
        }
        
        self.init(name: name, dataType: T.defaultDataType, flags: flags.union(extraFlags))
    }
}
