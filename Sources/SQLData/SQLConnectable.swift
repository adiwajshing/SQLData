//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 12/29/19.
//

import Foundation
import Promises

public protocol SQLConnectable {
    
    ///The dispatch queue on which async operations will be run
    var defaultDispatchQueue: DispatchQueue { get }
    
    ///Open a connection to the database asyncronously
    func open () -> Promise<Void>
    func close ()
    
    func query (_ q: String, row: (([String?]) -> Void)?) -> Promise<Void>
}
public extension SQLConnectable {
    
    func query (table q: String) -> Promise<[[String?]]> {
        var rows = [[String?]]()
        return query(q) { row in rows.append(row) }.then (on: defaultDispatchQueue) { rows }
    }
    func query (queries: [String]) -> Promise<Void> {

        var promise = Promise<Void>(())
        for i in queries.indices {
            promise = promise.then(on: defaultDispatchQueue, { self.query(queries[i], row: nil) })
        }
       // promise.fulfill(())
        return promise
    }
    
}
public func makeTable <T> (q: String, _ rowFunction: (String, @escaping (T) -> Void) -> Promise<Void> ) -> Promise<[T]> {
    var rows = [T]()
    return rowFunction(q, { rows.append($0) }).then({ rows })
}
