//
//  SoftDeletableExtension.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 22/09/1447 AH.
//

extension SoftDeletable {
    public static var isSoftDeletable: Bool { true }
    
    public func restore() throws {
        var record = self
        record.deleted_at = nil
        
        try BoltSpark.db.write { db in
            try record.update(db)
        }
    }
    
    public func forceDelete() throws {
        try BoltSpark.db.write { db in
            _ = try self.delete(db)
        }
    }
    
    public static func withTrashed() -> QueryBuilder<Self> {
        return Self.query().withTrashed()
    }

    public static func onlyTrashed() -> QueryBuilder<Self> {
        return Self.query().onlyTrashed()
    }
}
