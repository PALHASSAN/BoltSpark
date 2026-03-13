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
    
    static var fillable: [String] { get }
    static var guarded: [String] { get }
    static var hidden: [String] { get }
    
    var id: Int64? { get set }
    static var isSoftDeletable: Bool { get }
    
    // Only working with "with" method
    static func applyRelation(_ name: String, to request: QueryInterfaceRequest<Self>) -> QueryInterfaceRequest<Self>
}

extension Model {
    public static var databaseTableName: String {
        return tableName
    }
    
    public static var tableName: String {
        return "\(String(describing: self).lowercased())s"
    }
    
    
    public static func query() -> QueryBuilder<Self> {
        return QueryBuilder(request: Self.all())
    }
    
    public static var fillable: [String] { [] }
    public static var guarded: [String] { ["id"] }
    public static var hidden: [String] { [] }
    
    public static var isSoftDeletable: Bool { false }
    
    // Only working with "with" method
    public static func applyRelation(_ name: String, to request: QueryInterfaceRequest<Self>) -> QueryInterfaceRequest<Self> {
        print("⚠️ BoltSpark: Relation '\(name)' not found on \(Self.tableName).")
        return request
    }
    
    private static func sanitize(_ data: [String: Any]) -> [String: Any] {
        var sanitized = data
        
        if !fillable.isEmpty {
            sanitized = sanitized.filter { fillable.contains($0.key) }
        }
        
        sanitized = sanitized.filter { !guarded.contains($0.key) }
        
        return sanitized
    }
    
    public static func create(_ data: [String: Any]) throws -> Self {
        let safeData = sanitize(data)
        
        let jsonData = try JSONSerialization.data(withJSONObject: safeData)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        var record = try decoder.decode(Self.self, from: jsonData)
        return try record.create()
    }
    
    @discardableResult
    public mutating func create() throws -> Self {
        if var timeModel = self as? any Timestamps {
            let now = Date()
            timeModel.created_at = now
            timeModel.updated_at = now
            self = timeModel as! Self
        }
        
        try BoltSpark.db.write { db in
            try self.insert(db)
        }
        return self
    }
    
    public mutating func update() throws -> Self {
        if var timeModel = self as? any Timestamps {
            timeModel.updated_at = Date()
            self = timeModel as! Self
        }
        
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
    
    @discardableResult
    public func delete() throws -> Self {
        var copy = self
        
        if var softModel = copy as? any SoftDeletable {
            softModel.deleted_at = Date()
            copy = softModel as! Self
            
            try BoltSpark.db.write { db in
                _ = try self.update(db)
            }
        } else {
            try BoltSpark.db.write { db in
                _ = try self.delete(db)
            }
        }
        
        return copy
    }
    
    public static func `where`(_ column: String, _ value: some DatabaseValueConvertible) -> QueryBuilder<Self> { query().where(column, value) }
    public static func `where`(_ column: String, _ operator: String, _ value: some DatabaseValueConvertible) -> QueryBuilder<Self> {
        return query().where(column, `operator`, value)
    }
    public static func whereIn(_ column: String, _ values: [some DatabaseValueConvertible]) -> QueryBuilder<Self> {
        return query().whereIn(column, values)
    }
    public static func whereNull(_ column: String) -> QueryBuilder<Self> { return query().whereNull(column) }
    public static func whereNotNull(_ column: String) -> QueryBuilder<Self> { return query().whereNotNull(column) }
    public static func orWhere(_ column: String, _ value: some DatabaseValueConvertible) -> QueryBuilder<Self> {
        return query().orWhere(column, value)
    }
    
    public static func select(_ columns: [String]) -> QueryBuilder<Self> { return query().select(columns) }
    
    public static func find(_ id: some DatabaseValueConvertible) throws -> Self? { return try query().find(id) }
    public static func first() throws -> Self? { return try query().first() }
    public static func firstOrFail() throws -> Self { return try query().firstOrFail() }
    public static func get() throws -> [Self] { return try query().get() }
    public static func all() throws -> [Self] { return try query().all() }
    public static func orderBy(_ column: String, desc: Bool = false) -> QueryBuilder<Self> {
        return query().orderBy(column, desc: desc)
    }
    
    public static func limit(_ n: Int) -> QueryBuilder<Self> { return query().limit(n) }
    public static func count() throws -> Int { return try query().count() }
    public static func exists() throws -> Bool { return try query().exists() }
    
    public static func withTrashed() -> QueryBuilder<Self> { return query().withTrashed() }
    public static func onlyTrashed() -> QueryBuilder<Self> { return query().onlyTrashed() }
}
