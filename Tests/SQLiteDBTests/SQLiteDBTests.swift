import XCTest
@testable import SQLData
@testable import SQLiteDB

final class SQLiteDBTests: XCTestCase {

    let url = URL(fileURLWithPath: "/Volumes/PandaPartition/sqldatatest.db")
    
    func openDB (completion: @escaping (SQLConnectable) -> Void ) {
        let db = SQLiteDB(url: url)
        db.open { (error) in
            if let error = error {
                print("error: \(error)")
                return
            }
            completion(db)
        }
    }
    
    func initStructures (completion: @escaping (SQLConnectable) -> Void ) {
        openDB { (db) in
            Student.initializeStructure(on: db) { (error) in
                XCTAssertNil(error, "error in structure init: \(error!)")
                print("structure init success")
                completion(db)
            }
        }
    }
    func testInsert () {
        let group = DispatchGroup()
        group.enter()
        initStructures { db in
            let student = Student()
            student.fullName = "Jeff Singh"
            student.grades = [ .A, .B ]
            student.bestFriend = Student()
            student.bestFriend!.id = 2
            student.bestFriend!.grades = [.C, .B]
            
            student.insert(on: db, includeReferences: true) { (error) in
                XCTAssertNil(error, "error in inserting data: \(error!)")
                print("data inserted")
                group.leave()
            }

        }
        group.wait()
    }
    func testSelect () {
        
        openDB { (db) in
            Student.select(where: "", on: db, row: { item in
                print("\(item.id), \(item.fullName)")
            }) { error in
                XCTAssertNil(error, "error in selecting data: \(error!)")
            }
            
        }
        
    }
    func testSelectColumn () {
        
        openDB { (db) in
            Student.select(\Student.id, where: "", on: db, row: { id in
                print("\(id)")
            }) { error in
                XCTAssertNil(error, "error in selecting data: \(error!)")
            }
            
        }
        
    }
    func testInheritanceInsertAndSelect () {
        
        openDB(completion: { db in
            Person.initializeStructure(on: db) { (error) in
                XCTAssertNil(error, "error in init structure: \(error!)")
                
                PersonWithHouse.initializeStructure(on: db) { (error) in
                    XCTAssertNil(error, "error in init structure: \(error!)")
                    
                    print("structure init success")
                    
                    
                    print(PersonWithHouse.structureDescription().map({$0.query}))
                    print(PersonWithHouse.primaryKeyPath!.flags)
                    
                    let p = PersonWithHouse()
                    p.id = 20
                    p.name = "Jeff"
                    p.houseNumber = 40

                    p.insert(on: db, includeReferences: true) { error in
                        XCTAssertNil(error, "error in insert: \(error!)")
                        
                        PersonWithHouse.select(where: "", on: db, row: { (person) in
                            
                        }) { error in
                            XCTAssertNil(error, "error in insert: \(error!)")
                        }
                    }
                }
            }
        })
        usleep(1000*1000)
    }
    func testManyInsertAndSelect () {
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
        
        initStructures { (db) in
            
            let group = DispatchGroup()
            
            for student in data {
                group.enter()
                student.insert(on: db, includeReferences: true) { (error) in
                    XCTAssertNil(error, "error in inserting data: \(error!)")
                    group.leave()
                }
            }
            
            group.notify(queue: db.defaultDispatchQueue) {
                print("multiple insert success")
                var i = 0
                Student.select(where: "id % 2 == 0 ORDER BY id", on: db, row: { item in
                    XCTAssertEqual(item, data[i])
                    i += 1
                }) { error in
                    XCTAssertNil(error, "error in selecting data: \(error!)")
                    print("multiple select success")
                }

            }
            
            
        }
        
        usleep(5000 * 1000)
    }

  /*  static var allTests = [
        ("testExample", testExample),
    ]*/
}

