//
//  Schema.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 22/09/1447 AH.
//

import Foundation
import GRDB

struct Schema {
    /// Create new table
    public static func create(_ tableName: String, callback: (Blueprint) -> Void) throws {
        try BoltSpark.db.write { db in
            var blueprint: Blueprint?
            
            try db.create(table: tableName) { tableDefinition in
                let bPrint = Blueprint(tableDefinition)
                callback(bPrint)
                bPrint.build()
                blueprint = bPrint
            }
            
            if let b = blueprint {
                for idx in b.pendingIndexes {
                    let defaultName = "\(tableName)_\(idx.columns.joined(separator: "_"))_index"
                    let indexName = idx.name ?? defaultName
                    try db.create(index: indexName, on: tableName, columns: idx.columns)
                }
            }
        }
    }
    
    // Drop (Delete) table
    public static func dropIfExists(_ tableName: String) throws {
        try BoltSpark.db.write { db in
            try db.drop(table: tableName)
        }
    }
    
    // Rename table
    public static func rename(_ from: String, to: String) throws {
        try BoltSpark.db.write { db in
            try db.rename(table: from, to: to)
        }
    }
}
