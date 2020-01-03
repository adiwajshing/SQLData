//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 1/3/20.
//

import Foundation
import SQLData

class Person: SQLDataConvertible {
    var id: UInt32 = 0
    var name: String = ""
    
    required init () { }
    
    class var primaryKeyPath: SQLData.KeyPathDataColumn? {
        return .init(item: \Person.id, name: "id", flags: [.primaryKey])
    }
    class var mainKeyPaths: [SQLData.KeyPathDataColumn] {
        [
            SQLData.KeyPathDataColumn(item: \Person.name, name: "name", flags: [])
        ]
    }
    
    static let subKeyPaths: [SQLData.KeyPathArrayColumn] = []
    
}
class PersonWithHouse: Person {
    
    var superclass: Person {
        get { return self as Person }
        set { }
    }
    
    var houseNumber: Int = 20
    
    override class var primaryKeyPath: SQLData.KeyPathDataColumn? {
        return try! SQLData.KeyPathDataColumn(dataPath: \PersonWithHouse.superclass, name: "person", flags: [.primaryKey], referencing: true)
    }
    override class var mainKeyPaths: [SQLData.KeyPathDataColumn] {
        [
            SQLData.KeyPathDataColumn(item: \PersonWithHouse.houseNumber, name: "house_number", flags: [])
        ]
    }
}
