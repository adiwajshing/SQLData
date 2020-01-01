//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 12/29/19.
//

import Foundation

public extension SQLData {
    
    struct KeyPathDataColumn {
        public let keyPath: AnyKeyPath
        public let dataType: SQLDataConvertible.Type
        
        public let flags: FieldFlag
        public let referencing: Bool
        public let items: [KeyPathItemColumn]

        public init<K: SQLDataConvertible, V: SQLItemConvertible>(keyPath: WritableKeyPath<K, V>, name: String, dataType: DataType? = nil, flags: FieldFlag) {
            self.keyPath = keyPath
            self.dataType = V.self
            self.flags = flags.union(.notNull)
            
            if let dataType = dataType {
                self.items = [ KeyPathItemColumn(keyPath: keyPath, column: SQLData.Column(name: name, dataType: dataType, flags: flags)) ]
            } else {
                self.items = [ KeyPathItemColumn(keyPath: keyPath, column: Column(name: name, fromType: V.self, flags: flags)) ]
            }
            
            self.referencing = false
        }
        public init<K: SQLDataConvertible, V: SQLItemConvertible>(keyPath: WritableKeyPath<K, V?>, name: String, dataType: DataType? = nil, flags: FieldFlag) {
            self.keyPath = keyPath
            self.dataType = V.self
            self.flags = flags.subtracting(.notNull)
            
            if let dataType = dataType {
                self.items = [ KeyPathItemColumn(keyPath: keyPath, column: SQLData.Column(name: name, dataType: dataType, flags: flags)) ]
            } else {
                self.items = [ KeyPathItemColumn(keyPath: keyPath, column: Column(name: name, fromType: V.self, flags: flags)) ]
            }
            
            self.referencing = false
        }
        
        fileprivate init<K: SQLDataConvertible, V: SQLDataConvertible>(keyPathNonOp: WritableKeyPath<K, V>?, keyPathOp: WritableKeyPath<K, V?>?, name: String, flags: SQLData.FieldFlag, referencing: Bool) throws {
            
            if V.self is SQLItemConvertible {
                throw SQLData.Error.error("Use")
            }
            
            if K.self is V && !referencing {
                throw SQLData.Error.error("Cannot use self as a column, as it will create a loop; set referencing: true to fix")
            }
            
            if referencing && flags.contains(.primaryKey) {
                throw Error.error("a reference to a data structure cannot be a primary key")
            }

            let keyPath = keyPathNonOp ?? keyPathOp!
            
            self.keyPath = keyPath
            self.dataType = V.self
            self.flags = flags
            self.referencing = referencing
            
            var items = [KeyPathItemColumn]()
            
            let dataKeyPaths: [[SQLData.KeyPathItemColumn]]
            if referencing {
                if let primaryKey = V.primaryKeyPath {
                    dataKeyPaths = [primaryKey.items]
                } else {
                    throw Error.primaryKeyAbsent
                }
            } else {
                dataKeyPaths = V.mainKeyPaths.map({$0.items})
            }
            
            for kpItems in dataKeyPaths {
                let it = kpItems.map({ item -> KeyPathItemColumn in
                    if let keyPath = keyPathNonOp {
                        return KeyPathItemColumn(prefixing: keyPath, prefixingName: "\(name)_", flags: item.column.flags, toItemColumn: item)
                    } else {
                        return KeyPathItemColumn(prefixing: keyPathOp!, prefixingName: "\(name)_", flags: item.column.flags.subtracting(.notNull), toItemColumn: item)
                    }
                })
                items.append(contentsOf: it)

            }
            
            self.items = items
        }
        internal init (initalizingForSubKeyPath prefix: String, onto keyPath: KeyPathDataColumn) {
            self.keyPath = keyPath.keyPath
            self.dataType = keyPath.dataType
            self.flags = keyPath.flags.subtracting(.primaryKey)
            self.items = keyPath.items.map({ KeyPathItemColumn(prefixingName: prefix, toItemColumn: $0) })
            self.referencing = keyPath.referencing
        }
        
        func columns () -> [Column] {
            if self.flags.contains(.primaryKey) {
                return items.map({$0.column})
            }
            return items.map({$0.column.with(flags: $0.column.flags.subtracting(.primaryKey))})
        }
        func uniquelyIndexedColumns () -> [Column]? {
            if flags.contains(.primaryKey) {
                if items.count == 1, items.first!.column.flags.contains(.primaryKey) {
                    return nil
                } else {
                    return items.map({$0.column})
                }
            }
            return nil
        }
        
    }
    
}
public extension SQLData.KeyPathDataColumn {
    
    init<K: SQLDataConvertible, V: SQLDataConvertible>(dataPath path: WritableKeyPath<K, V>, name: String, flags: SQLData.FieldFlag, referencing: Bool = false) throws {
        try self.init(keyPathNonOp: path, keyPathOp: nil, name: name, flags: flags.union(.notNull), referencing: referencing)
    }
    init<K: SQLDataConvertible, V: SQLDataConvertible>(dataPath path: WritableKeyPath<K, V?>, name: String, flags: SQLData.FieldFlag, referencing: Bool = false) throws {
        
        if K.self is V && !(V.self is SQLItemConvertible) && !referencing {
            throw SQLData.Error.error("Cannot use self as a column, as it will create a loop; set referencing: true to fix")
        }
        try self.init(keyPathNonOp: nil, keyPathOp: path, name: name, flags: flags.subtracting(.notNull), referencing: referencing)
    }
    
}
public extension SQLData {
    struct KeyPathItemColumn {
        let path: [(AnyKeyPath, SQLDataConvertible.Type)]
        let column: Column
        
        init <K: SQLDataConvertible, V: SQLDataConvertible>(keyPath: WritableKeyPath<K, V>, column: Column) {
            self.path = [(keyPath, V.self)]
            self.column = column
        }
        init <K: SQLDataConvertible, V: SQLDataConvertible>(keyPath: WritableKeyPath<K, Optional<V>>, column: Column) {
            self.path = [(keyPath, V.self)]
            self.column = column
        }
        init<K: SQLDataConvertible, V: SQLDataConvertible> (prefixing keyPath: WritableKeyPath<K, V>, prefixingName name: String, flags: FieldFlag, toItemColumn column: KeyPathItemColumn) {
            var path = column.path
            path.insert((keyPath, V.self), at: 0)
            self.path = path
            self.column = Column(name: name + column.column.name, dataType: column.column.dataType, flags: flags)
        }
        init<K: SQLDataConvertible, V: SQLDataConvertible> (prefixing keyPath: WritableKeyPath<K, V?>, prefixingName name: String, flags: FieldFlag, toItemColumn column: KeyPathItemColumn) {
            var path = column.path
            path.insert((keyPath, V.self), at: 0)
            self.path = path
            self.column = Column(name: name + column.column.name, dataType: column.column.dataType, flags: flags)
        }
        init (prefixingName name: String = "", withFlags flags: FieldFlag? = nil, toItemColumn column: KeyPathItemColumn) {
            self.path = column.path
            self.column = Column(name: name + column.column.name, dataType: column.column.dataType, flags: flags ?? column.column.flags)
        }
        
    }
}
