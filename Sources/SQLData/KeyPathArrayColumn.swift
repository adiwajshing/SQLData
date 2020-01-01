//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 1/1/20.
//

import Foundation

public extension SQLData {
    
    struct KeyPathArrayColumn {
        public let keyPath: AnyKeyPath
        
        public let keyName: String
        
        public let referencing: Bool
        
        public let mappingKeyPath: KeyPathDataColumn
        public let indexingColumn: Column?
        public let accessedItems: [KeyPathItemColumn]
        
        public let dataType: SQLDataConvertible.Type
        
        public init<K: SQLDataConvertible, V: SQLDataConvertible>(keyPath: WritableKeyPath<K, [V]>, name: String, orderData: Bool = true, referencing: Bool = false) throws {
            
            self.keyPath = keyPath
            self.referencing = referencing
            self.keyName = K.tableName + "_" + name
            self.dataType = V.self
            
            if let primaryKey = K.primaryKeyPath {
                self.mappingKeyPath = KeyPathDataColumn(initalizingForSubKeyPath: K.tableName + "_", onto: primaryKey)
            } else {
                throw Error.primaryKeyAbsent
            }
            
            if orderData {
                self.indexingColumn = Column(name: "array_index", dataType: .long, flags: [.notNull])
            } else {
                self.indexingColumn = nil
            }
            
            var items = [KeyPathItemColumn]()
            if referencing {
                if let dataTypePrimaryKey = dataType.primaryKeyPath {
                    items = dataTypePrimaryKey.items
                } else {
                    throw Error.primaryKeyAbsent
                }
            } else {
                for p in dataType.mainKeyPaths {
                    items.append(contentsOf: p.items)
                }
            }
            
            items = items.map({ KeyPathItemColumn(prefixingName: "", withFlags: $0.column.flags.subtracting(.primaryKey), toItemColumn: $0) } )
            self.accessedItems = items
        }
        
        public func selectQuery (matching arr: [String]) -> String {
            
            let tableName = referencing ? dataType.tableName : keyName
            
            let columns = dataType.mainKeyPaths.map({ $0.items.map({"\(tableName).'\($0.column.name)'"}).joined(separator: ", ") }).joined(separator: ", ")
            let matchClause = mappingKeyPath.items.indices.map({ "\(mappingKeyPath.items[$0].column.name)=='\(arr[$0])'" })
            let orderedClause = indexingColumn == nil ? "" : " ORDER BY \(indexingColumn!.name)"
            return "SELECT \(columns) FROM \(tableName) WHERE \(matchClause.joined(separator: " AND "))\(orderedClause)"
        }
        
    }
    
}
