//
//  QueryBuilder.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 25/09/1447 AH.
//

import Foundation

public class QueryBuilder<T: Model> {
    private var selectedColumns: [String] = ["*"]
    private var wheres: [(sql: String, connector: String)] = []
    private var arguments: [Any] = []
    private var orders: [String] = []
    private var limitCount: Int?
    private var offsetCount: Int?
    private var _withTrashed: Bool = false
    private var _onlyTrashed: Bool = false
    
    private var eagerLoads: [String] = []
    
    public init() {}
    
    // MARK: - Where Clauses
    @discardableResult
    public func `where`(_ column: String, _ opOrValue: Any, _ value: Any? = nil) -> Self {
        return addWhere(column: column, opOrValue: opOrValue, value: value, connector: "AND")
    }
    
    @discardableResult
    public func orWhere(_ column: String, _ opOrValue: Any, _ value: Any? = nil) -> Self {
        return addWhere(column: column, opOrValue: opOrValue, value: value, connector: "OR")
    }
    
    private func addWhere(column: String, opOrValue: Any, value: Any?, connector: String) -> Self {
        if let actualValue = value {
            wheres.append(("\(column) \(opOrValue) ?", connector))
            arguments.append(actualValue)
        } else {
            wheres.append(("\(column) = ?", connector))
            arguments.append(opOrValue)
        }
        return self
    }
    
    @discardableResult
    public func whereIn(_ column: String, _ values: [Any]) -> Self {
        guard !values.isEmpty else { return self }
        let placeholders = String(repeating: "?,", count: values.count).dropLast()
        wheres.append(("\(column) IN (\(placeholders))", "AND"))
        arguments.append(contentsOf: values)
        return self
    }
    
    @discardableResult
    public func whereNull(_ column: String) -> Self {
        wheres.append(("\(column) IS NULL", "AND"))
        return self
    }
    
    @discardableResult
    public func whereNotNull(_ column: String) -> Self {
        wheres.append(("\(column) IS NOT NULL", "AND"))
        return self
    }
    
    @discardableResult
    public func orWhereNull(_ column: String) -> Self {
        wheres.append(("\(column) IS NULL", "OR"))
        return self
    }

    @discardableResult
    public func orWhereNotNull(_ column: String) -> Self {
        wheres.append(("\(column) IS NOT NULL", "OR"))
        return self
    }
    
    // MARK: - Select & Order & Limit
    public func select(_ columns: [String]) -> Self {
        self.selectedColumns = columns
        return self
    }
    
    public func orderBy(_ column: String, desc: Bool = false) -> Self {
        let direction = desc ? "DESC" : "ASC"
        orders.append("\(column) \(direction)")
        return self
    }
    
    public func limit(_ limit: Int, offset: Int? = nil) -> Self {
        self.limitCount = limit
        self.offsetCount = offset
        return self
    }
    
    // MARK: - Execution Methods
    public func get() throws -> [T] {
        let sql = buildSQL()
        let driver = try BoltSpark.driver(for: T.databaseName)
        let rawData = try driver.fetch(sql, arguments: arguments)
        
        var models = try ModelMapper.map(rawData, to: T.self)
        
        if !eagerLoads.isEmpty && !models.isEmpty {
            try performEagerLoading(on: &models)
        }
        return models
    }
    
    public func all() throws -> [T] {
        return try get()
    }
    
    public func first() throws -> T? {
        return try self.limit(1).get().first
    }
    
    public func firstOrFail() throws -> T {
        guard let result = try first() else {
            throw BoltError.mappingError("Record not found in \(T.tableName)")
        }
        return result
    }
    
    public func find(_ id: Int64) throws -> T? {
        return try self.where("id", id).first()
    }
    
    public func count() throws -> Int {
        let sql = "SELECT COUNT(*) as total FROM (\(buildSQL()))"
        let driver = try BoltSpark.driver(for: T.databaseName)
        let result = try driver.fetch(sql, arguments: arguments)
        return Int(result.first?["total"] as? Int64 ?? 0)
    }
    
    public func exists() throws -> Bool {
        return try count() > 0
    }
    
    @discardableResult
    public func delete() throws -> Bool {
        let driver = try BoltSpark.driver(for: T.databaseName)
        var sql = ""
        
        if T.isSoftDeletable && !_withTrashed {
            sql = "UPDATE \(T.tableName) SET deleted_at = CURRENT_TIMESTAMP"
        } else {
            sql = "DELETE FROM \(T.tableName)"
        }
        
        sql += buildWhereClause()
        try driver.execute(sql, arguments: arguments)
        return true
    }
    
    @discardableResult
    public func with(_ relations: [String]) -> Self {
        self.eagerLoads.append(contentsOf: relations)
        return self
    }
    
    public func withTrashed() -> Self {
        self._withTrashed = true
        return self
    }
    
    public func onlyTrashed() -> Self {
        self._withTrashed = true
        self._onlyTrashed = true
        return self
    }
    
    // MARK: - Internal SQL Builder
    private func buildWhereClause() -> String {
        var finalConditions = wheres
        
        if T.isSoftDeletable && !_withTrashed {
            let condition = _onlyTrashed ? "deleted_at IS NOT NULL" : "deleted_at IS NULL"
            finalConditions.append((condition, "AND"))
        }
        
        if finalConditions.isEmpty { return "" }
        
        var sql = " WHERE "
        
        for (index, condition) in finalConditions.enumerated() {
            if index == 0 {
                sql += condition.sql
            } else {
                sql += " \(condition.connector) \(condition.sql)"
            }
        }
        
        return sql
    }
    
    private func buildSQL() -> String {
        var sql = "SELECT \(selectedColumns.joined(separator: ", ")) FROM \(T.tableName)"
        
        sql += buildWhereClause()
        
        if !orders.isEmpty {
            sql += " ORDER BY " + orders.joined(separator: ", ")
        }
        
        if let limit = limitCount {
            sql += " LIMIT \(limit)"
            if let offset = offsetCount { sql += " OFFSET \(offset)" }
        }
        
        return sql
    }
}


extension QueryBuilder {
    public func paginate(page: Int, perPage: Int = 15) throws -> Paginator<T> {
        let total = try self.count()
        let offset = (page - 1) * perPage
        
        let items = try self.limit(perPage, offset: offset).get()
        
        return Paginator(data: items, total: total, perPage: perPage, currentPage: page)
    }
    
    // MARK: - Sorting by desc
    public func latest(_ column: String = "created_at") -> Self {
        return self.orderBy(column, desc: true)
    }
    
    public func oldest(_ column: String = "created_at") -> Self {
        return self.orderBy(column, desc: false)
    }
}


extension QueryBuilder {
    private func performEagerLoading(on models: inout [T]) throws {
        let parentIds = models.compactMap { $0.idValue }
        if parentIds.isEmpty { return }
 
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let template = try? decoder.decode(T.self, from: "{}".data(using: .utf8)!) else { return }
        
        let templateMirror = Mirror(reflecting: template)
        
        var groupedRelations: [String: [String]] = [:]
        for path in eagerLoads {
            let parts = path.split(separator: ".")
            let root = String(parts[0])
            let remaining = parts.dropFirst().map(String.init).joined(separator: ".")
            
            if groupedRelations[root] == nil { groupedRelations[root] = [] }
            if !remaining.isEmpty { groupedRelations[root]?.append(remaining) }
        }
        
        for (relationName, nestedPaths) in groupedRelations {
            guard let child = templateMirror.children.first(where: {
                $0.label?.replacingOccurrences(of: "_", with: "") == relationName
            }), let templateRelation = child.value as? BoltRelation else { continue }
            
            let relatedType = templateRelation.relatedModelType
            try openAndLoad(relatedType, models: &models, relation: templateRelation, relationName: relationName, parentIds: parentIds, nested: nestedPaths)
        }
    }
    
    private func openAndLoad<M: Model>(_ type: M.Type, models: inout [T], relation: BoltRelation, relationName: String, parentIds: [Int64], nested: [String]) throws {
        let placeholders = String(repeating: "?,", count: parentIds.count).dropLast()
        var sql = ""
        var args: [Any] = parentIds
        
        if let pivot = relation.pivotConfig(parentTable: T.tableName) {
            sql = "SELECT \(M.tableName).*, \(pivot.table).\(pivot.parentKey) as pivot_parent_id FROM \(M.tableName) INNER JOIN \(pivot.table) ON \(M.tableName).id = \(pivot.table).\(pivot.relatedKey) WHERE \(pivot.table).\(pivot.parentKey) IN (\(placeholders))"
            for (col, val) in relation.extraConditions(parentTable: T.tableName) {
                sql += " AND \(pivot.table).\(col) = ?"; args.append(val)
            }
        } else {
            let foreignKey = relation.guessKey(parentTable: T.tableName)
            sql = "SELECT * FROM \(M.tableName) WHERE \(foreignKey) IN (\(placeholders))"
            for (col, val) in relation.extraConditions(parentTable: T.tableName) {
                sql += " AND \(col) = ?"; args.append(val)
            }
        }
        
        let driver = try BoltSpark.driver(for: M.databaseName)
        let rawData = try driver.fetch(sql, arguments: args)
        let relatedModels = try ModelMapper.map(rawData, to: M.self)
        
        var finalRelatedModels = relatedModels
        if !nested.isEmpty && !finalRelatedModels.isEmpty {
            var erased = finalRelatedModels as [any Model]
            try eagerLoadNested(models: &erased, type: M.self, relations: nested)
            finalRelatedModels = erased.compactMap { $0 as? M }
        }
        
        for i in 0..<models.count {
            let pid = models[i].idValue
            
            let m = Mirror(reflecting: models[i])
            if let child = m.children.first(where: { $0.label?.replacingOccurrences(of: "_", with: "") == relationName }),
               let modelRelation = child.value as? BoltRelation {
                
                if relation.pivotConfig(parentTable: T.tableName) != nil {
                    let childIds = rawData.filter { ($0["pivot_parent_id"] as? Int64) == pid }.compactMap { $0["id"] as? Int64 }
                    let filtered = finalRelatedModels.filter { childIds.contains($0.idValue ?? -1) }
                    modelRelation.setRelationData(filtered)
                } else {
                    let foreignKey = relation.guessKey(parentTable: T.tableName)
                    let filtered = finalRelatedModels.filter { child in
                        let cm = Mirror(reflecting: child)
                        return cm.children.contains { $0.label?.toSnakeCase() == foreignKey && ($0.value as? Int64) == pid }
                    }
                    modelRelation.setRelationData(filtered)
                }
            }
        }
    }
    
    private func eagerLoadNested(models: inout [any Model], type: any Model.Type, relations: [String]) throws {
        func openAndLoadInner<M: Model>(_ type: M.Type, models: inout [any Model], relations: [String]) throws {
            var typedModels = models.compactMap { $0 as? M }
            if typedModels.isEmpty { return }
            
            let builder = QueryBuilder<M>()
            builder.with(relations)
            try builder.performEagerLoading(on: &typedModels)
            
            models = typedModels
        }
        try openAndLoadInner(type, models: &models, relations: relations)
    }
}

// MARK: Has Extension
extension QueryBuilder {
    @discardableResult
    public func has(_ relationName: String) -> Self {
        return buildHasCondition(relationName: relationName, isExists: true)
    }
    
    @discardableResult
    public func doesntHave(_ relationName: String) -> Self {
        return buildHasCondition(relationName: relationName, isExists: false)
    }
    
    @discardableResult
    public func whereHas(_ relationName: String, closure: (QueryBuilder<T>) -> Void) -> Self {
        let subQuery = QueryBuilder<T>()
        closure(subQuery)
        
        let (subSql, subArgs) = subQuery.buildConditionsOnly()
        
        return buildHasCondition(relationName: relationName, isExists: true, subQuerySql: subSql, subQueryArgs: subArgs)
    }
    
    @discardableResult
    public func whereDoesntHave(_ relationName: String, closure: (QueryBuilder<T>) -> Void) -> Self {
        let subQuery = QueryBuilder<T>()
        closure(subQuery)
        
        let (subSql, subArgs) = subQuery.buildConditionsOnly()
        
        return buildHasCondition(relationName: relationName, isExists: false, subQuerySql: subSql, subQueryArgs: subArgs)
    }
    
    private func buildHasCondition(relationName: String, isExists: Bool, subQuerySql: String? = nil, subQueryArgs: [Any] = []) -> Self {
        let mirror = Mirror(reflecting: T.self)
        guard let child = mirror.children.first(where: {
            $0.label?.replacingOccurrences(of: "_", with: "") == relationName
        }), let relation = child.value as? BoltRelation else { return self }
        
        let relatedTable = relation.relatedModelType.tableName
        let existsKeyword = isExists ? "EXISTS" : "NOT EXISTS"
        var sql = ""
        
        if let pivot = relation.pivotConfig(parentTable: T.tableName) {
            sql = "\(existsKeyword) (SELECT 1 FROM \(relatedTable) INNER JOIN \(pivot.table) ON \(relatedTable).id = \(pivot.table).\(pivot.relatedKey) WHERE \(pivot.table).\(pivot.parentKey) = \(T.tableName).id"
            
            for (col, val) in relation.extraConditions(parentTable: T.tableName) {
                sql += " AND \(pivot.table).\(col) = ?"
                self.arguments.append(val)
            }
        } else {
            let foreignKey = relation.guessKey(parentTable: T.tableName)
            sql = "\(existsKeyword) (SELECT 1 FROM \(relatedTable) WHERE \(relatedTable).\(foreignKey) = \(T.tableName).id"
            
            for (col, val) in relation.extraConditions(parentTable: T.tableName) {
                sql += " AND \(relatedTable).\(col) = ?"
                self.arguments.append(val)
            }
        }
        
        if let subSql = subQuerySql, !subSql.isEmpty {
            sql += " AND \(subSql)"
            self.arguments.append(contentsOf: subQueryArgs)
        }
        
        sql += ")"
        self.wheres.append((sql, "AND"))
        
        return self
    }
    
    public func buildConditionsOnly() -> (sql: String, arguments: [Any]) {
        if wheres.isEmpty { return ("", []) }
        var sql = ""
        for (index, condition) in wheres.enumerated() {
            sql += index == 0 ? condition.sql : " \(condition.connector) \(condition.sql)"
        }
        return (sql, arguments)
    }
}
