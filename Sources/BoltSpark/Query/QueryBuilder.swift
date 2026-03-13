//
//  QueryBuilder.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 21/09/1447 AH.
//

import GRDB
import Foundation

public class QueryBuilder<T: Model> {
    private var request: QueryInterfaceRequest<T>
    var assembledCondition: SQLExpression?
    
    private var _withTrashed: Bool = false
    private var _onlyTrashed: Bool = false
    
    private func buildRequest() -> QueryInterfaceRequest<T> {
        var finalRequest = request
        
        if let finalCondition = self.assembledCondition {
            finalRequest = finalRequest.filter(finalCondition)
        }
        
        if T.isSoftDeletable {
            if _onlyTrashed {
                finalRequest = finalRequest.filter(Column("deleted_at") != nil)
            } else if !_withTrashed {
                finalRequest = finalRequest.filter(Column("deleted_at") == nil)
            }
        }
        
        return finalRequest
    }
    
    init(request: QueryInterfaceRequest<T>) {
        self.request = request
    }
    
    public func _whereRaw(_ sql: String, arguments: StatementArguments = []) -> Self {
        let builder = self
        let newCondition = sql.sqlExpression
        
        builder.assembledCondition = builder.assembledCondition.map { $0 && newCondition } ?? newCondition
        return builder
    }
    
    public func `where`(_ column: String, _ operator: String, _ value: some DatabaseValueConvertible) -> Self {
        let builder = self
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
    /// User.where("active", 1)
    public func `where`(_ column: String, _ value: some DatabaseValueConvertible) -> Self {
        return self.where(column, "=", value)
    }
    
    /// User.whereIn("id", [1, 2, 3])
    public func whereIn(_ column: String, _ values: [some DatabaseValueConvertible]) -> Self {
        let builder = self
        let newExpr = values.contains(Column(column))
        builder.assembledCondition = builder.assembledCondition.map { $0 && newExpr } ?? newExpr
        return builder
    }
    
    /// User.whereNull("deleted_at")
    public func whereNull(_ column: String) -> Self {
        let builder = self
        let newCondition = (Column(column) == nil)
        builder.assembledCondition = builder.assembledCondition.map { $0 && newCondition } ?? newCondition
        return builder
    }
    
    /// User.whereNotNull("deleted_at")
    public func whereNotNull(_ column: String) -> Self {
        let builder = self
        let newCondition = (Column(column) != nil)
        builder.assembledCondition = builder.assembledCondition.map { $0 && newCondition } ?? newCondition
        return builder
    }
    
    /// User.where("active", 1).orWhere("role", "admin")
    public func orWhere(_ column: String, _ value: some DatabaseValueConvertible) -> Self {
        let builder = self
        let newCondition = (Column(column) == value)
        
        builder.assembledCondition = builder.assembledCondition.map { $0 || newCondition } ?? newCondition
        return builder
    }
    
    /// User.select(["id", "name"])
    public func select(_ columns: [String]) -> Self {
        let builder = self
        builder.request = request.select(columns.map { Column($0) })
        return builder
    }
    
    public func find(_ id: some DatabaseValueConvertible) throws -> T? {
        return try BoltSpark.db.read { db in
            try buildRequest().filter(key: id).fetchOne(db)
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
        let builder = self
        let order = desc ? Column(column).desc : Column(column).asc
        builder.request = request.order(order)
        return builder
    }
    
    /// e.g. User.with(["projects", "profile"])
    public func with(_ relations: [String]) -> Self {
        self.request = relations.reduce(self.request) { currentRequest, relation in
            T.applyRelation(relation, to: currentRequest)
        }
        return self
    }
    
    /// e.g. User.with("projects", "profile")
    public func with(_ relations: String...) -> Self {
        return self.with(relations)
    }
    
    public func limit(_ limit: Int, offset: Int? = nil) -> Self {
        let builder = self
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
    
    @discardableResult
    public func delete() throws -> Int {
        return try BoltSpark.db.write { db in
            if T.isSoftDeletable {
                return try buildRequest().updateAll(db, [Column("deleted_at").set(to: Date())])
            } else {
                return try buildRequest().deleteAll(db)
            }
        }
    }
    
    public func withTrashed() -> Self {
        self._withTrashed = true
        return self
    }
    
    public func onlyTrashed() -> Self {
        self._onlyTrashed = true
        return self
    }
}
