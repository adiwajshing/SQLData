//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 12/29/19.
//

import Foundation

public protocol SQLConnectable {
    
    ///The dispatch queue on which async operations will be run
    var defaultDispatchQueue: DispatchQueue { get }
    
    func open (_ completion: @escaping (Error?) -> Void )
    func close ()
    
    func query (_ q: String, completion: @escaping (Error?) -> Void )
    func query (_ q: String, table: @escaping ([String: Int], [[String?]], Error?) -> Void)
}
public extension SQLConnectable {
    
    func query (queries: [String], completion: @escaping (Error?) -> Void) {

        var error: Error?
        let group = DispatchGroup()
        
        for query in queries {
            group.enter()
            self.query(query) { (e) in
                if let e = e, error == nil {
                    error = e
                }
                group.leave()
            }
        }
        
        group.notify(queue: self.defaultDispatchQueue) {
            completion(error)
        }
    }
    
}
