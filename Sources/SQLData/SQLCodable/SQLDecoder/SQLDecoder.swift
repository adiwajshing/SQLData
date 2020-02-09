import Foundation

public typealias SQLRowedData = [ String: [[String:String]] ]
final class SQLEncodedData {
    var dictionary: SQLRowedData = .init()
}

public let sqlNullValue = "NULL"
public let sqlDictionaryKeyReferencingKey = "key"
public let sqlSingleValueReferencingKey = "value"
public let sqlRefKeyPrefix = "_"
public let sqlKeySeperator = "."

struct DataPath {
    var tableName: String
    var key: String
    var row: Int
    
    func keyString (for codingKey: CodingKey) -> String {
        return key.isEmpty ? codingKey.stringValue : key+sqlKeySeperator+codingKey.stringValue
    }
}

open class SQLDecoder: Decoder {
    
    public let codingPath: [CodingKey]
    public var userInfo: [CodingUserInfoKey : Any] = [:]
    
    private let data: SQLRawData
    
    private let path: DataPath
    
    public init <S: SQLCodable> (_ t: S.Type, data: SQLRowedData) {
        self.path = DataPath(tableName: S.tableName, key: "", row: 0)
        self.codingPath = []
        
        self.data = .init()
        self.data.dictionary = data
    }
    
    init (path: DataPath, data: SQLEncodedData, codingPath: [CodingKey]) {
        self.path = path
        self.data = data
        self.codingPath = codingPath
    }

    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        //print("\(Key.self), \(path)")
        if let dict = data.dictionary[path.tableName + sqlKeySeperator + path.key]?.first, sqlIsDictionary(dict: dict) {
            return .init (
                try SQLDictionaryContainer(path: path, data: data, codingPath: codingPath)
            )
        }
        
        return .init(
            SQLKeyedContainer<Key>(path: path, data: data, codingPath: codingPath)
        )
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        try SQLUnkeyedContainer(path: path, data: data, codingPath: codingPath)
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        SQLSingleValueDecoder(path: path, data: data, codingPath: codingPath)
    }

}
