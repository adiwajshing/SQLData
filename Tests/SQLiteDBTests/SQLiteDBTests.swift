import XCTest
import Promises
@testable import SQLData
@testable import SQLiteDB

final class SQLiteDBTests: XCTestCase {

    let db = SQLiteDB(url: URL(fileURLWithPath: "/Volumes/PandaPartition/sqldatatest.db") )
    
    func openDB () -> Promise<Void> {
        return db.open().catch(on: db.defaultDispatchQueue, {  XCTFail("Error in opening DB: \($0)") } )
    }
    
    func initStructures () -> Promise<Void> {
        let f = openDB()
            .then(on: db.defaultDispatchQueue, { Student.initializeStructure(on: self.db) })
            .then(on: db.defaultDispatchQueue, { print("structure init success") })
            .catch(on: db.defaultDispatchQueue, {  XCTFail("Error in init structures: \($0)") } )
        return f
    }
    func testInsert () throws {

        let p =
            initStructures()
            .then(on: db.defaultDispatchQueue) { _ -> Promise<Void> in
                let student = Student()
                student.fullName = "Jeff da first"
                student.bestFriend = Student()
                student.bestFriend?.id = 2
                student.bestFriend?.fullName = "P.P. Poo"
                student.grades = [ .A, .Aminus, .C ]
            
                return student.insert(on: self.db, include: .all)
            }
            .then(on: db.defaultDispatchQueue) { print("insert success") }
        
        try await(p)
    }
    func testUpdate () throws {
        let p = openDB()
        .then(on: db.defaultDispatchQueue) {
            Student().update(\Student.fullName, on: self.db)
        }
        .then(on: db.defaultDispatchQueue) { print("update success") }
        
        try await(p)
    }
    func testSelect () throws {
        
        let p = openDB()
            .then(on: db.defaultDispatchQueue) { Student.select(where: "", on: self.db, include: .all) }
        
        let table = try await(p)
        print(table)
    }
    func testSelectColumn () throws {
        let p = openDB()
            .then(on: db.defaultDispatchQueue) { _ in Student.select(\Student.id, where: "", on: self.db, row: { print($0) }, include: .all) }
        
        try await(p)
    }
    func testInheritanceInsertAndSelect () throws {
        let p =
            openDB()
            .then(on: db.defaultDispatchQueue) { Person.initializeStructure(on: self.db) }
            .then(on: db.defaultDispatchQueue) { PersonWithHouse.initializeStructure(on: self.db) }
            .then(on: db.defaultDispatchQueue) { _ -> Promise<Void> in
                
                let p = PersonWithHouse()
                p.id = 20
                p.name = "Jeff"
                p.houseNumber = 40
                
                return p.insert(on: self.db, include: .all)
            }
            .then(on: db.defaultDispatchQueue) { PersonWithHouse.select(where: "", on: self.db, include: .all) }
        let table = try await(p)
        
        XCTAssertTrue(table.count > 0)
        XCTAssertEqual(table[0].id, 20)
        XCTAssertEqual(table[0].name, "Jeff")
        XCTAssertEqual(table[0].houseNumber, 40)
    }
    func testManyInsertAndSelect () throws {
        let range = 0..<1000
        var data = [Student]()
        for i in stride(from: range.lowerBound, to: range.upperBound, by: 2) {
            let student = Student()
            student.id = UInt32(i)
            student.fullName = "Jeff Singh \(i)"
            student.grades = (0..<4).map { _ in Grade(rawValue: Int32(arc4random() % 4) )! }
            
            student.bestFriend = Student()
            student.bestFriend!.id = UInt32(i+1)
            student.bestFriend!.fullName = "P.P. PooPoo \(i)"
            student.bestFriend!.grades = (0..<4).map { _ in Grade(rawValue: Int32(arc4random() % 4) )! }
            
            data.append(student)
        }
        
        var i = 0
        let p =
            initStructures()
            .then (on: db.defaultDispatchQueue) { Student.insert(data, on: self.db, include: .all) }
            .then (on: db.defaultDispatchQueue) { _ in
                return Student.select(where: "id % 2 == 0 ORDER BY id", on: self.db, row: {
                    XCTAssertEqual($0, data[i])
                    i += 1
                }, include: .all)
            }
        
        try await(p)
    }

  /*  static var allTests = [
        ("testExample", testExample),
    ]*/
}

