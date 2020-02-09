//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 1/1/20.
//  Sample Data

import Foundation
import SQLData

class Student: SQLDataConvertible, Codable {
    var id: UInt32 = 0
    var fullName: String = ""
    
    var bestFriend: Student?
    var grades: [Grade] = []
    
    required init() {
        
    }
    
    public static let primaryKeyPath: SQLData.KeyPathDataColumn? =
        SQLData.KeyPathDataColumn(item: \Student.id, name: "id", flags: [.primaryKey])
    
    public static let mainKeyPaths: [SQLData.KeyPathDataColumn] =
        [
            try! SQLData.KeyPathDataColumn(dataPath: \Student.bestFriend, name: "best_friend", flags: [], referencing: true),
            SQLData.KeyPathDataColumn(item: \Student.fullName, name: "name", flags: [])
        ]
    
    public static let subKeyPaths: [SQLData.KeyPathArrayColumn] =
        [
            try! SQLData.KeyPathArrayColumn(keyPath: \Student.grades, name: "grades")
        ]
    
}
extension Student: Equatable {
    static func == (_ lhs: Student, _ rhs: Student) -> Bool {
        return lhs.id == rhs.id && rhs.fullName == lhs.fullName && lhs.bestFriend == rhs.bestFriend && lhs.grades == rhs.grades
    }
}
public enum Grade: Int32, SQLEnumConvertible, Codable {
    case A = 0
    case Aminus = 1
    case B = 2
    case Bminus = 3
    case C = 4
    case D = 5
    case F = 6
}
