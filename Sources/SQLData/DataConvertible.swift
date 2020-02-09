//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 12/29/19.
//

import Foundation

public protocol SQLDataConvertible {
    
    static var tableName: String { get }
    
    static var primaryKeyPath: SQLData.KeyPathDataColumn? { get }
    
    static var mainKeyPaths: [ SQLData.KeyPathDataColumn ] { get }
    static var subKeyPaths: [ SQLData.KeyPathArrayColumn ] { get }
    
    init ()
    
    func postProcess (on connectable: SQLConnectable, _ completion: @escaping (Error?) -> Void )
}
public extension SQLDataConvertible {
    
    func postProcess (on connectable: SQLConnectable, _ completion: @escaping (Error?) -> Void ) { completion(nil) }
}
public struct SQLDataIOOptions: OptionSet {
    public let rawValue: UInt8

    public static let referencedValues = Self.init(rawValue: 1)
    public static let subValues = Self.init(rawValue: 2)
    public static let all = Self.init([ .referencedValues, .subValues ])
    
    public init(rawValue: UInt8) {
        
        self.rawValue = rawValue
    }
}

/*extension ClosedRange : SQLDataConvertible where Bound: SQLItemConvertible {
    
    public init() {
        self.init(uncheckedBounds: (Bound.init(), Bound.init()))
    }
    
    public static var primaryKeyPath: SQLData.KeyPathDataColumn? { nil }
    public static var mainKeyPaths: [SQLData.KeyPathDataColumn] {
        [
            SQLData.KeyPathDataColumn(item: \Self.lowerBound, name: "start", flags: []),
            SQLData.KeyPathDataColumn(item: \Self.upperBound, name: "end", flags: [])
        ]
    }
    
    public static var subKeyPaths: [SQLData.KeyPathArrayColumn] { [] }
    
}*/
