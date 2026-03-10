//
//  Model.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 21/09/1447 AH.
//

import Foundation
import GRDB

public protocol Model: FetchableRecord, MutablePersistableRecord, Codable {
    static var tableName: String { get }
    
    static var guarded: [String] { get }
    var id: Int64? { get set }
}

extension Model {
    public static var tableName: String {
        return "\(String(describing: self).lowercased())s"
    }
    
    public static func query() -> QueryBuilder<Self> {
        return QueryBuilder(request: Self.all())
    }
    
    public static var guarded: [String] {
        return ["id"]
    }
    
    @discardableResult
    public mutating func create() throws -> Self {
        try BoltSpark.db.write { db in
            try self.insert(db)
        }
        return self
    }
    
    public mutating func update() throws -> Self {
        try BoltSpark.db.write { db in
            try self.update(db)
        }
        return self
    }
    
    public mutating func save() throws {
        try BoltSpark.db.write { db in
            try self.save(db)
        }
    }
            
    public mutating func delete() throws {
        try BoltSpark.db.write { db in
            _ = try self.delete(db)
        }
    }
    
    public static func `where`(_ column: String, _ value: some DatabaseValueConvertible) -> QueryBuilder<Self> { query().where(column, value) }
    public static func `where`(_ column: String, _ operator: String, _ value: some DatabaseValueConvertible) -> QueryBuilder<Self> {
        return query().where(column, `operator`, value)
    }
    public static func orderBy(_ column: String, desc: Bool = false) -> QueryBuilder<Self> { query().orderBy(column, desc: desc) }
    public static func limit(_ n: Int) -> QueryBuilder<Self> { query().limit(n) }
    public static func with<Child: Model>(_ relation: HasManyAssociation<Self, Child>) -> QueryBuilder<Self> { query().with(relation) }
    public static func with<Parent: Model>(_ relation: BelongsToAssociation<Self, Parent>) -> QueryBuilder<Self> { query().with(relation) }
    public static func get() throws -> [Self] { try query().get() }
    public static func first() throws -> Self? { try query().first() }
}
