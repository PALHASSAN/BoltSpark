//
//  QueryBuilder.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 21/09/1447 AH.
//

import GRDB

public struct QueryBuilder<T: Model> {
    private var request: QueryInterfaceRequest<T>
    
    private var assembledCondition: SQLExpression?
    
    private func buildRequest() -> QueryInterfaceRequest<T> {
        if let finalCondition = self.assembledCondition {
            return request.filter(finalCondition)
        }
        return request
    }
    
    init(request: QueryInterfaceRequest<T>) {
        self.request = request
    }
    
    public func `where`(_ column: String, _ operator: String, _ value: some DatabaseValueConvertible) -> Self {
        var builder = self
        let col = Column(column)
        let newCondition: SQLExpression
        
        switch `operator` {
        case "=":  newCondition = (col == value)
        case ">":  newCondition = (col > value)
        case "<":  newCondition = (col < value)
        case ">=": newCondition = (col >= value)
        case "<=": newCondition = (col <= value)
        case "!=": newCondition = (col != value)
        default:   newCondition = (col == value)
        }
        
        builder.assembledCondition = builder.assembledCondition.map { $0 && newCondition } ?? newCondition
        return builder
    }
    
    // By defalut is =
    /// User.query().where("active", 1)
    public func `where`(_ column: String, _ value: some DatabaseValueConvertible) -> Self {
        return self.where(column, "=", value)
    }
    
    /// User.query().whereIn("id", [1, 2, 3])
    public func whereIn(_ column: String, _ values: [some DatabaseValueConvertible]) -> Self {
        var builder = self
        let newExpr = values.contains(Column(column))
        builder.assembledCondition = builder.assembledCondition.map { $0 && newExpr } ?? newExpr
        return builder
    }
    
    /// User.whereNull("deleted_at")
    public func whereNull(_ column: String) -> Self {
        var builder = self
        let newCondition = (Column(column) == nil)
        builder.assembledCondition = builder.assembledCondition.map { $0 && newCondition } ?? newCondition
        return builder
    }
    
    /// User.whereNotNull("deleted_at")
    public func whereNotNull(_ column: String) -> Self {
        var builder = self
        let newCondition = (Column(column) != nil)
        builder.assembledCondition = builder.assembledCondition.map { $0 && newCondition } ?? newCondition
        return builder
    }
    
    /// User.where("active", 1).orWhere("role", "admin")
    public func orWhere(_ column: String, _ value: some DatabaseValueConvertible) -> Self {
        var builder = self
        let newCondition = (Column(column) == value)
        
        builder.assembledCondition = builder.assembledCondition.map { $0 || newCondition } ?? newCondition
        return builder
    }
    
    /// User.select(["id", "name"])
    public func select(_ columns: [String]) -> Self {
        var builder = self
        builder.request = request.select(columns.map { Column($0) })
        return builder
    }
    
    public func find(_ id: some DatabaseValueConvertible) throws -> T? {
        return try BoltSpark.db.read { db in
            try T.filter(key: id).fetchOne(db)
        }
    }
    
    public func first() throws -> T? {
        return try BoltSpark.db.read { db in
            try buildRequest().fetchOne(db)
        }
    }
    
    public func firstOrFail() throws -> T {
        guard let record = try first() else {
            throw BoltError.modelNotFound("Record not found in \(T.tableName)")
        }
        
        return record
    }
    
    public func get() throws -> [T] {
        return try BoltSpark.db.read { db in
            try buildRequest().fetchAll(db)
        }
    }
    
    public func all() throws -> [T] {
        return try get()
    }
    
    /// orderBy("created_at", desc: true)
    public func orderBy(_ column: String, desc: Bool = false) -> Self {
        var builder = self
        let order = desc ? Column(column).desc : Column(column).asc
        builder.request = request.order(order)
        return builder
    }
    
    public func with<Child: Model>(_ association: HasManyAssociation<T, Child>) -> Self {
        var builder = self
        builder.request = request.including(all: association)
        return builder
    }
    
    public func with<Parent: Model>(_ association: BelongsToAssociation<T, Parent>) -> Self {
        var builder = self
        builder.request = request.including(optional: association)
        return builder
    }
    
    public func limit(_ limit: Int, offset: Int? = nil) -> Self {
        var builder = self
        builder.request = request.limit(limit, offset: offset)
        return builder
    }
    
    public func count() throws -> Int {
        return try BoltSpark.db.read { db in
            try buildRequest().fetchCount(db)
        }
    }
    
    public func exists() throws -> Bool {
        return try count() > 0
    }
}
