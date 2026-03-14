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
    let database: DatabaseWriter
    var assembledCondition: SQLExpression?
    
    private var _withTrashed: Bool = false
    private var _onlyTrashed: Bool = false
    
    init(request: QueryInterfaceRequest<T>, database: DatabaseWriter) {
        self.request = request
        self.database = database
    }
    
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
    
    // MARK: - Where Clauses
    public func _whereRaw(_ sql: String, arguments: StatementArguments = []) -> Self {
        let newCondition = sql.sqlExpression
        self.assembledCondition = self.assembledCondition.map { $0 && newCondition } ?? newCondition
        return self
    }
    
    public func `where`(_ column: String, _ operator: String, _ value: some DatabaseValueConvertible) -> Self {
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
        
        self.assembledCondition = self.assembledCondition.map { $0 && newCondition } ?? newCondition
        return self
    }
    
    public func `where`(_ column: String, _ value: some DatabaseValueConvertible) -> Self {
        return self.where(column, "=", value)
    }
    
    public func whereIn(_ column: String, _ values: [some DatabaseValueConvertible]) -> Self {
        let newExpr = values.contains(Column(column))
        self.assembledCondition = self.assembledCondition.map { $0 && newExpr } ?? newExpr
        return self
    }
    
    public func whereNull(_ column: String) -> Self {
        let newCondition = (Column(column) == nil)
        self.assembledCondition = self.assembledCondition.map { $0 && newCondition } ?? newCondition
        return self
    }
    
    public func whereNotNull(_ column: String) -> Self {
        let newCondition = (Column(column) != nil)
        self.assembledCondition = self.assembledCondition.map { $0 && newCondition } ?? newCondition
        return self
    }
    
    public func orWhere(_ column: String, _ value: some DatabaseValueConvertible) -> Self {
        let newCondition = (Column(column) == value)
        self.assembledCondition = self.assembledCondition.map { $0 || newCondition } ?? newCondition
        return self
    }
    
    public func select(_ columns: [String]) -> Self {
        self.request = request.select(columns.map { Column($0) })
        return self
    }
    
    public func orderBy(_ column: String, desc: Bool = false) -> Self {
        let order = desc ? Column(column).desc : Column(column).asc
        self.request = request.order(order)
        return self
    }
    
    public func limit(_ limit: Int, offset: Int? = nil) -> Self {
        self.request = request.limit(limit, offset: offset)
        return self
    }

    // MARK: - Executing Methods
    public func find(_ id: some DatabaseValueConvertible) throws -> T? {
        try database.read { db in try buildRequest().filter(key: id).fetchOne(db) }
    }
    
    public func first() throws -> T? {
        try database.read { db in try buildRequest().fetchOne(db) }
    }
    
    public func firstOrFail() throws -> T {
        guard let record = try first() else {
            throw BoltError.modelNotFound("Record not found in \(T.tableName)")
        }
        return record
    }
    
    public func get() throws -> [T] {
        try database.read { db in try buildRequest().fetchAll(db) }
    }
    
    public func all() throws -> [T] {
        try get()
    }
    
    public func count() throws -> Int {
        try database.read { db in try buildRequest().fetchCount(db) }
    }
    
    public func exists() throws -> Bool {
        try count() > 0
    }
    
    @discardableResult
    public func delete() throws -> Int {
        try database.write { db in
            if T.isSoftDeletable {
                return try buildRequest().updateAll(db, [Column("deleted_at").set(to: Date())])
            } else {
                return try buildRequest().deleteAll(db)
            }
        }
    }

    // MARK: - Eager Loading
    public func with(_ relations: [String]) -> Self {
        self.request = relations.reduce(self.request) { currentRequest, relation in
            T.applyRelation(relation, to: currentRequest)
        }
        return self
    }
    
    public func with(_ relations: String...) -> Self {
        return self.with(relations)
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
