//
//  Model.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 25/09/1447 AH.
//

import Foundation

public protocol Model: Codable {
    static var tableName: String { get }
    static var databaseName: String { get }
    static var isSoftDeletable: Bool { get }
  
}

extension Model {
    // User -> users
    public static var tableName: String {
        return "\(String(describing: self).lowercased())s"
    }
    
    public static var databaseName: String { "main" }
    public static var isSoftDeletable: Bool { false }
    
    func extractSchema() -> [String: Any] {
        var schema: [String: Any] = [:]
        let mirror = Mirror(reflecting: self)
        
        for child in mirror.children {
            if let label = child.label {
                if label == "id" || label.hasPrefix("_") { continue }
                schema[label.toSnakeCase()] = child.value
            }
        }
        return schema
    }
    
    var idValue: Int64? {
        let mirror = Mirror(reflecting: self)
        return mirror.children.first(where: { $0.label == "id" })?.value as? Int64
    }
}

// - MARK: Direct Querying
extension Model {
    @discardableResult
    public static func `where`(_ column: String, _ opOrValue: Any, _ value: Any? = nil) -> QueryBuilder<Self> {
        return QueryBuilder<Self>().where(column, opOrValue, value)
    }
    
    @discardableResult
    public static func orWhere(_ column: String, _ opOrValue: Any, _ value: Any? = nil) -> QueryBuilder<Self> {
        return QueryBuilder<Self>().orWhere(column, opOrValue, value)
    }
    
    @discardableResult
    public static func whereIn(_ column: String, _ values: [Any]) -> QueryBuilder<Self> {
        return QueryBuilder<Self>().whereIn(column, values)
    }
    
    @discardableResult
    public static func whereNull(_ column: String) -> QueryBuilder<Self> {
        return QueryBuilder<Self>().whereNull(column)
    }
    
    @discardableResult
    public static func whereNotNull(_ column: String) -> QueryBuilder<Self> {
        return QueryBuilder<Self>().whereNotNull(column)
    }
    
    public static func select(_ columns: [String]) -> QueryBuilder<Self> {
        return QueryBuilder<Self>().select(columns)
    }
    
    public static func orderBy(_ column: String, desc: Bool = false) -> QueryBuilder<Self> {
        return QueryBuilder<Self>().orderBy(column, desc: desc)
    }
    
    public static func limit(_ limit: Int, offset: Int? = nil) -> QueryBuilder<Self> {
        return QueryBuilder<Self>().limit(limit, offset: offset)
    }
}

// MARK: - Quick Fetching
extension Model {
    public static func all() throws -> [Self] {
        return try QueryBuilder<Self>().get()
    }
    
    public static func first() throws -> Self? {
        return try QueryBuilder<Self>().first()
    }
    
    public static func find(_ id: Int64) throws -> Self? {
        return try QueryBuilder<Self>().find(id)
    }
    
    public static func count() throws -> Int {
        return try QueryBuilder<Self>().count()
    }
}
