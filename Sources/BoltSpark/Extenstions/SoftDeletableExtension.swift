//
//  SoftDeletableExtension.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 22/09/1447 AH.
//

import Foundation

extension SoftDeletable {
    public static var isSoftDeletable: Bool { true }
    
    public func restore() throws {
        let driver = try BoltSpark.driver(for: Self.databaseName)
        guard let id = self.idValue else { return }
        
        let sql = "UPDATE \(Self.tableName) SET deleted_at = NULL WHERE id = ?"
        try driver.execute(sql, arguments: [id])
    }
    
    public func forceDelete() throws {
        let driver = try BoltSpark.driver(for: Self.databaseName)
        guard let id = self.idValue else { return }
        
        let sql = "DELETE FROM \(Self.tableName) WHERE id = ?"
        try driver.execute(sql, arguments: [id])
    }
    
    public static func withTrashed() -> QueryBuilder<Self> {
        return QueryBuilder<Self>().withTrashed()
    }
    
    public static func onlyTrashed() -> QueryBuilder<Self> {
        return QueryBuilder<Self>().onlyTrashed()
    }
}
