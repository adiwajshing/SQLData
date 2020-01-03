//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 12/29/19.
//

import Foundation

public protocol SQLConnectable {
    
    var isConcurrencyCapable: Bool { get  }
    
    ///The dispatch queue on which async operations will be run
    var defaultDispatchQueue: DispatchQueue { get }
    
    ///Open a connection to the database asyncronously
    func open (_ completion: @escaping (Error?) -> Void )
    func close ()
    
    func query (_ q: String, row: (([String?]) -> Void)?, completion: @escaping (Error?) -> Void)
}
public extension SQLConnectable {
    
    func query (_ q: String, table: @escaping ([[String?]], Error?) -> Void) {
        var rows = [[String?]]()
        query(q, row: { rows.append($0) }, completion: { error in table(rows, error) })
    }
    
    func query (unorderedQueries queries: [String], completion: @escaping (Error?) -> Void) {

        var error: Error?
        let group = DispatchGroup()
        
        DispatchQueue.concurrentPerform(iterations: queries.count) { i in
            group.enter()
            self.query(queries[i], row: nil) { e in
                if let e = e, error == nil {
                    error = e
                }
                group.leave()
            }
        }
        
        group.notify(queue: self.defaultDispatchQueue) { completion(error) }
    }
    
}
