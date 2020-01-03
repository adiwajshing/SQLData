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

fileprivate typealias SQLiteCallback = ((Int32, UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?, UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?, Swift.Error?) -> Void)

public class SQLiteDB: SQLConnectable {
    
    public let isConcurrencyCapable = true
    public let defaultDispatchQueue: DispatchQueue = DispatchQueue(label: "label", attributes: [])
    
    public let url: URL
    
    private var db: OpaquePointer!
    
    public init (url: URL) {
        self.url = url
    }
    public func open(_ completion: @escaping (Swift.Error?) -> Void) {
        var db: OpaquePointer?
        let result = sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX | SQLITE_OPEN_CREATE, nil)
        
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
    
    public func query (_ q: String, row: (([String?]) -> Void)?, completion: @escaping (Swift.Error?) -> Void) {
        
        var err: UnsafeMutablePointer<Int8>?
        let r: Int32

        if var rowCallback = row {
            r = sqlite3_exec(db, q, { keyContext, count, data, columnNames in
                let callback = keyContext!.assumingMemoryBound(to: (([String?]) -> Void).self).pointee
                let row = (0..<Int(count)).map { (i) -> String? in
                    if let data = data?[i] {
                        return String(cString: data)
                    }
                    return nil
                }
                callback(row)
                
                return 0
            }, &rowCallback, &err)
        } else {
            r = sqlite3_exec(db, q, { _, _, _, _ in return 0 }, nil, &err)
        }
        
        
        if r == SQLITE_OK {
            completion(nil)
        } else {
            let msg = String(cString: err!)
            completion(Error.errorInQuery(msg))
        }
    }
    
    public enum Error: Swift.Error {
        case openFailed(String)
        case dbNotOpen
        case errorInQuery (String)
    }

    
}
