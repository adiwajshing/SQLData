//
//  File.swift
//  
//
//  Created by Adhiraj Singh on 2/3/20.
//

import Foundation

public class SQLRawData {
    private(set) var columns = [String:Int]()
    private(set) var rows = [[String?]]()
    
    public func set (columns: [String]) {
        self.columns.removeAll()
        for i in columns.indices {
            self.columns[columns[i]] = i
        }
    }
    public func append (row: [String?]) {
        rows.append(row)
    }
    
    public subscript (_ row: Int, _ column: String) -> String? {
        if row >= rows.count { return nil }
        
        guard let columnIndex = columns[column] else { return nil }
        
        return rows[row][columnIndex]
    }
}
