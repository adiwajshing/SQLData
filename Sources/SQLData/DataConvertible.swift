//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 12/29/19.
//

import Foundation

public protocol SQLDataConvertible {
    
    static var primaryKeyPath: SQLData.KeyPathDataColumn? { get }
    
    static var mainKeyPaths: [ SQLData.KeyPathDataColumn ] { get }
    static var subKeyPaths: [ SQLData.KeyPathArrayColumn ] { get }
    
    init ()
}
