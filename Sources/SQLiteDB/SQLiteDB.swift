//
//  SQLiteDB.swift
//  CMDLine
//
//  Created by Adhiraj Singh on 3/27/18.
//  Copyright © 2018 Adhiraj Singh. All rights reserved.
//

import Foundation
import SQLite3
import SQLData

public class SQLiteDB: SQLConnectable {
    
    private typealias SQLiteCallback = ((Int32, UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?, UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Void)
    
    private static var sqliteCallback: SQLiteCallback?
    private static let sm = DispatchSemaphore(value: 1)
    
    public let defaultDispatchQueue: DispatchQueue = .global()
    public let url: URL
    
    private var db: OpaquePointer!
    
    public init (url: URL) {
        self.url = url
    }
    public func open(_ completion: @escaping (Swift.Error?) -> Void) {
        var db: OpaquePointer?
        let result = sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READWRITE|SQLITE_OPEN_FULLMUTEX|SQLITE_OPEN_CREATE, nil)
        
        if result == SQLITE_OK {
            print("successfully opened connection to database at \(url.path)")
            self.db = db!
            completion(nil)
        } else {
            let str = String(cString: strerror(errno))
            completion(Error.openFailed(str))
        }
    }
    public func close() {
        sqlite3_close(db)
        db = nil
    }
    
    public func query(_ q: String, completion: @escaping (Swift.Error?) -> Void) {
        do {
            try SQLiteDB.query(db: db, q: q, callback: nil)
            completion(nil)
        } catch {
            completion(error)
        }
    }
    public func query(_ q: String, table: @escaping ([String : Int], [[String?]], Swift.Error?) -> Void) {
        var columns = [String: Int]()
        var rows = [[String?]]()
        
        do {
            try SQLiteDB.query(db: db, q: q, callback: { (count, data, columnNames) in
                
                if columns.count == 0 {
                    for i in 0..<Int(count) {
                        columns[ String(cString: columnNames![i]!) ] = i
                    }
                }
                let row = (0..<Int(count)).map({ i -> String? in
                    if let data = data?[i] {
                        return String(cString: data)
                    }
                    return nil
                })
                
                rows.append(row)
            })
            table(columns, rows, nil)
        } catch {
            table(columns, rows, error)
        }
        
    }

    
    private static func query (db: OpaquePointer, q: String, callback: SQLiteCallback?) throws {
        
        sm.wait()
        
        defer {
            sm.signal()
        }
        
        sqliteCallback = callback
        
        var err: UnsafeMutablePointer<Int8>?
        var r: Int32 = 0
        
        r = sqlite3_exec(db, q, { notused, count, data, columnNames in
            SQLiteDB.sqliteCallback?(count, data, columnNames)
            return 0
        }, nil, &err)
        
        sqliteCallback = nil
        
        if r != SQLITE_OK {
            let msg = String(cString: err!)
            throw Error.errorInQuery(msg)
        }
        
    }
    
    public enum Error: Swift.Error {
        case openFailed(String)
        case dbNotOpen
        case errorInQuery (String)
    }

    
}
