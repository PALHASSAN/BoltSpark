//
//  SoftDeletableExtension.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 22/09/1447 AH.
//

import GRDB

extension SoftDeletable {
    public static var isSoftDeletable: Bool { true }
    private static var currentDb: DatabaseWriter { BoltSpark.connection(for: Self.databaseName) }
    
    public func restore() throws {
        var record = self
        record.deleted_at = nil
        
        try Self.currentDb.write { db in
                    try record.update(db)
        }
    }
    
    public func forceDelete() throws {
        try Self.currentDb.write { db in
                    _ = try self.delete(db)
        }
    }
    
    public static func withTrashed() -> QueryBuilder<Self> {
        return QueryBuilder(request: Self.all(), database: currentDb).withTrashed()
    }

    public static func onlyTrashed() -> QueryBuilder<Self> {
        return QueryBuilder(request: Self.all(), database: currentDb).onlyTrashed()
    }
}
