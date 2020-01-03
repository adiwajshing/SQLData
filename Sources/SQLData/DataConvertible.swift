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
