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

extension Model {
    public static func query() -> QueryBuilder<Self> {
        return QueryBuilder<Self>()
    }
    
    // MARK: - Proxy Fetching Methods
    public static func with(_ relations: String...) -> QueryBuilder<Self> {
        return query().with(relations)
    }

    public static func all() throws -> [Self] {
        return try query().get()
    }

    public static func find(_ id: Int64) throws -> Self? {
        return try query().find(id)
    }

    public static func first() throws -> Self? {
        return try query().first()
    }
    
    public static func firstOrFail() throws -> Self {
        return try query().firstOrFail()
    }

    public static func count() throws -> Int {
        return try query().count()
    }
    
    public static func exists() throws -> Bool {
        return try query().exists()
    }

    public static func paginate(page: Int, perPage: Int = 15) throws -> Paginator<Self> {
        return try query().paginate(page: page, perPage: perPage)
    }

    // MARK: - Proxy Query Methods (Chaining)
    @discardableResult
    public static func `where`(_ column: String, _ opOrValue: Any, _ value: Any? = nil) -> QueryBuilder<Self> {
        return query().where(column, opOrValue, value)
    }

    @discardableResult
    public static func orWhere(_ column: String, _ opOrValue: Any, _ value: Any? = nil) -> QueryBuilder<Self> {
        return query().orWhere(column, opOrValue, value)
    }

    @discardableResult
    public static func whereIn(_ column: String, _ values: [Any]) -> QueryBuilder<Self> {
        return query().whereIn(column, values)
    }
    
    @discardableResult
    public static func whereNull(_ column: String) -> QueryBuilder<Self> {
        return query().whereNull(column)
    }
    
    @discardableResult
    public static func whereNotNull(_ column: String) -> QueryBuilder<Self> {
        return query().whereNotNull(column)
    }
    
    @discardableResult
    public static func orWhereNull(_ column: String) -> QueryBuilder<Self> {
        return query().orWhereNull(column)
    }
    
    @discardableResult
    public static func orWhereNotNull(_ column: String) -> QueryBuilder<Self> {
        return query().orWhereNotNull(column)
    }
    
    public static func select(_ columns: [String]) -> QueryBuilder<Self> {
        return query().select(columns)
    }

    public static func orderBy(_ column: String, desc: Bool = false) -> QueryBuilder<Self> {
        return query().orderBy(column, desc: desc)
    }
    
    public static func latest(_ column: String = "created_at") -> QueryBuilder<Self> {
        return query().latest(column)
    }
    
    public static func oldest(_ column: String = "created_at") -> QueryBuilder<Self> {
        return query().oldest(column)
    }

    public static func limit(_ limit: Int, offset: Int? = nil) -> QueryBuilder<Self> {
        return query().limit(limit, offset: offset)
    }
    
    // MARK: - Soft Deletes Proxy
    public static func withTrashed() -> QueryBuilder<Self> {
        return query().withTrashed()
    }
    
    public static func onlyTrashed() -> QueryBuilder<Self> {
        return query().onlyTrashed()
    }
}
