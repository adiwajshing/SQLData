//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 12/29/19.
//

import Foundation

public extension SQLDataConvertible {
    
    static var tableName: String {
        return String(describing: Self.self)
    }
    
    static var dataKeyPaths: [SQLData.KeyPathDataColumn] {
        var keypaths = mainKeyPaths
        if let pK = primaryKeyPath {
            keypaths.insert(pK, at: 0)
        }
        return keypaths
    }
    
    static func structureDescription () -> [SQLData.StructureDescription] {
        
        var queries = [String: SQLData.StructureDescription]()

        var mainColumns = [SQLData.Column]()
        if let pKeyPath = primaryKeyPath {
            mainColumns.append(contentsOf: pKeyPath.columns())
        }
        
        for keyPath in mainKeyPaths {
            mainColumns.append(contentsOf: keyPath.columns())
            
            if let columnIndexes = keyPath.uniquelyIndexedColumns() {
                let structure = SQLData.StructureDescription(name: "\(tableName)_index", columns: columnIndexes, type: .uniqueIndex(tableName))
                queries[structure.name] = structure
            }
            
            queries.merge(keyPath.dataType.subStructureDescription(), uniquingKeysWith: {s0, s1 in return s0})
        }
        
        let mainStructure = SQLData.StructureDescription(name: tableName, columns: mainColumns, type: .table)
        queries[mainStructure.name] = mainStructure
        
        queries.merge(subStructureDescription(), uniquingKeysWith: {s0, s1 in return s0})

        let sortedQueries = queries.values.sorted { (s0, s1) -> Bool in
            switch s0.type {
            case .table:
                return true
            default:
                return false
            }
        }
        
        return sortedQueries
    }
    fileprivate static func subStructureDescription () -> [String: SQLData.StructureDescription] {
        
        var queries = [String: SQLData.StructureDescription]()
        
        let subKeyPaths = Self.subKeyPaths
        if subKeyPaths.count == 0 {
            return queries
        }
        
        for keyPath in subKeyPaths {
            
            var columns = [SQLData.Column]()
            columns.append(contentsOf: keyPath.mappingKeyPath.columns())
            if let column = keyPath.indexingColumn {
                columns.append(column)
            }
            columns.append(contentsOf: keyPath.accessedItems.map({$0.column}))
            
            let table = SQLData.StructureDescription(name: keyPath.keyName, columns: columns, type: .table)
            let indexes = SQLData.StructureDescription(name: keyPath.keyName + "_index", columns: keyPath.mappingKeyPath.columns(), type: .index(table.name))
            queries[table.name] = table
            queries[indexes.name] = indexes
            
            queries.merge(keyPath.dataType.subStructureDescription(), uniquingKeysWith: {s0, s1 in return s0})
        }

        return queries
    }
    
}
