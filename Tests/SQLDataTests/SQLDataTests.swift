import XCTest
import Promises
@testable import SQLData

final class SQLDataTests: XCTestCase {
    
    func testExample() throws {
        
        let data = [
            "TestClass": [
                [ "id": "1", "str": "Some String", "_selfRef.TestClass.id": "2",
                  "subStruct.id": "24", "subStruct.str": "More str", "optionalBool": "1"],
                [ "id": "2", "str": "Some String 2", "selfRef": "NULL",
                                 "subStruct.id": "22", "subStruct.str": "More str 2", "optionalBool": "NULL"]
            ],
            "TestClass.points": [
                [ "TestClass.id": "1", "value": "50.1" ],
                [ "TestClass.id": "1", "value": "50.3" ]
            ],
            "TestClass.grades": [
                [ "TestClass.id": "1", "value": "0" ],
                [ "TestClass.id": "1", "value": "3" ],
                [ "TestClass.id": "1", "value": "NULL" ],
                [ "TestClass.id": "1", "value": "2" ]
            ],
            "TestClass.subStruct.subDict": [
                [ "TestClass.subStruct.id": "24", "key.id": "23", "value": "5" ],
                [ "TestClass.subStruct.id": "24", "key.id": "11", "value": "6" ]
            ],
            "TestClass.subStruct.subDict.key.points": [
                [ "TestClass.subStruct.subDict.key.id": "24", "key": "abc", "value": "0.2" ],
                [ "TestClass.subStruct.subDict.key.id": "11", "key": "def", "value": "3.1" ],
                [ "TestClass.subStruct.subDict.key.id": "11", "key": "efg", "value": "3.4" ]
            ]
        ]
        
        let decoder = SQLDecoder(TestClass.self, data: data)
        let encoder = SQLEncoder(TestClass.self)
        do {
            let value = try TestClass(from: decoder)
            print(value)
            try value.encode(to: encoder)
            print(encoder.data.dictionary)
        } catch {
            XCTFail("ERROR: \(error)")
        }
        
        
    }
    func testPromise () {
        
        
    }
    
    static var allTests = [
        ("testExample", testExample),
    ]
}
final class TestClass: SQLCodable {
    var id: UInt64
    var str: String
    var optionalBool: Bool?
    
    var points: [Float]
    var grades: [Grade?]
    
    var selfRef: TestClass?
    var subStruct: SubStruct
    
    struct SubStruct: SQLCodable {
        
        var id: UInt64
        var str: String
        var subDict: [SubSubStruct: Int?]
        
        static let options: [CodingUserInfoKey : SQLCodingOptions] = [
            .init(CodingKeys.id): .flags(.primaryKey)
        ]
        
        struct SubSubStruct: SQLCodable, Hashable {
            var id: UInt64
            var points: [String:Float]
            
            static let options: [CodingUserInfoKey : SQLCodingOptions] = [
                .init(CodingKeys.id): .flags(.primaryKey)
            ]
        }
    }
    
    static let options: [CodingUserInfoKey : SQLCodingOptions] = [
        .init(CodingKeys.id): .flags(.primaryKey),
        .init(CodingKeys.str): .dataType(.char(30)),
        .init(CodingKeys.selfRef): .referenced(CodingKeys.id, CodingKeys.id)
    ]
}
public enum Grade: UInt32, Codable {
    case A = 0
    case Aminus = 1
    case B = 2
    case Bminus = 3
    case C = 4
    case D = 5
    case F = 6
}

