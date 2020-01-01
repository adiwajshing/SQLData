public struct SQLData {
    public typealias MetaData = [Column]
    
    public struct StructureDescription: CustomStringConvertible {
        let name: String
        let columns: [Column]
        let type: StructureType
        
        public var description: String {
            return "'\(name)' '\(type)' (\(columns.map({$0.name}).joined(separator: ", ")))"
        }
        public var query: String {
            let columnDescription = columns.map({$0.description}).joined(separator: ", ")
            switch type {
            case .table:
                return "CREATE TABLE IF NOT EXISTS '\(name)' (\(columnDescription))"
            case .index(let table):
                return "CREATE INDEX IF NOT EXISTS '\(name)' ON \(table)(\(columns.map({$0.name}).joined(separator: ", ")))"
            case .uniqueIndex(let table):
                return "CREATE UNIQUE INDEX IF NOT EXISTS '\(name)' ON \(table)(\(columns.map({$0.name}).joined(separator: ", ")))"
            }
            
        }
        
        public enum StructureType {
            case table
            case index (String)
            case uniqueIndex (String)
        }
    }
    
    public class Table<T: SQLDataConvertible> {
        public var rows: [T]
        
        internal init (count: Int) {
            rows = (0..<count).map( { _ in T.init() } )
        }
        public var description: String {
            return "{" + rows.map({ "\($0)" }).joined(separator: ",\n") + "}"
        }

    }
    
    public enum Error: Swift.Error {
        case duplicateColumnNames (String, String)
        case dataConversionFailed
        case primaryKeyAbsent
        case error (String)
    }
}
