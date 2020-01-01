import XCTest
@testable import SQLData

final class SQLDataTests: XCTestCase {
    
    
    func testExample() {
        
        print(Student.structureDescription().map({$0.query}))
        var student = Student()
        student.bestFriend = Student()
        student.bestFriend?.id = 2
        
        print(student.stringDescription(includeReferences: true))
       /* print(TestData.structureDescription())
        print(TestData.selectMainTableQuery(where: ""))
        
        var testData = TestData()
        testData[keyPath: \.name] = "hello"
        print(testData.insertQueries())
        
        print(TestData.NumberData.subKeyPaths[0].selectQuery(matching: ["3"]))
        
      //  print(testData.address.houseNumber)*/
        
    }
    
    static var allTests = [
        ("testExample", testExample),
    ]
}

