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
}

extension Model {
    private static var builder: QueryBuilder<Self> { QueryBuilder(request: Self.all()) }
    
    public static func `where`(_ column: String, _ value: some DatabaseValueConvertible) -> QueryBuilder<Self> { builder.where(column, value) }
    public static func `where`(_ column: String, _ operator: String, _ value: some DatabaseValueConvertible) -> QueryBuilder<Self> { builder.where(column, `operator`, value) }
    public static func whereIn(_ column: String, _ values: [some DatabaseValueConvertible]) -> QueryBuilder<Self> { builder.whereIn(column, values) }
    public static func whereNull(_ column: String) -> QueryBuilder<Self> { builder.whereNull(column) }
    public static func whereNotNull(_ column: String) -> QueryBuilder<Self> { builder.whereNotNull(column) }
    public static func orWhere(_ column: String, _ value: some DatabaseValueConvertible) -> QueryBuilder<Self> { builder.orWhere(column, value) }
    
    public static func select(_ columns: [String]) -> QueryBuilder<Self> { builder.select(columns) }
    public static func orderBy(_ column: String, desc: Bool = false) -> QueryBuilder<Self> { builder.orderBy(column, desc: desc) }
    public static func limit(_ n: Int) -> QueryBuilder<Self> { builder.limit(n) }
    
    public static func with(_ relations: String...) -> QueryBuilder<Self> { builder.with(relations) }
    public static func has(_ relation: String) -> QueryBuilder<Self> { builder.has(relation) }
    public static func doesntHave(_ relation: String) -> QueryBuilder<Self> { builder.doesntHave(relation) }
    public static func whereHas(_ relation: String, closure: (QueryBuilder<Self>) -> Void) -> QueryBuilder<Self> { builder.whereHas(relation, closure: closure) }
    public static func whereDoesntHave(_ relation: String, closure: (QueryBuilder<Self>) -> Void) -> QueryBuilder<Self> { builder.whereDoesntHave(relation, closure: closure) }
    
    public static func find(_ id: some DatabaseValueConvertible) throws -> Self? { try builder.find(id) }
    public static func first() throws -> Self? { try builder.first() }
    public static func firstOrFail() throws -> Self { try builder.firstOrFail() }
    public static func get() throws -> [Self] { try builder.get() }
    public static func all() throws -> [Self] { try builder.all() }
    public static func count() throws -> Int { try builder.count() }
    public static func exists() throws -> Bool { try builder.exists() }
    public static func paginate(page: Int = 1, perPage: Int = 15) throws -> Paginator<Self> { try builder.paginate(page: page, perPage: perPage) }
    
    public static func withTrashed() -> QueryBuilder<Self> { builder.withTrashed() }
    public static func onlyTrashed() -> QueryBuilder<Self> { builder.onlyTrashed() }
}
