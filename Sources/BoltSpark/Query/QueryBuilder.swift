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
            do {
                try performEagerLoading(on: &models)
            } catch {
                #if DEBUG
                print("⚠️ BoltSpark Eager Loading failed: \(error)")
                #endif
            }
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
    public func with(_ relations: String...) -> Self {
        self.eagerLoads.append(contentsOf: relations)
        return self
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
                if val.hasPrefix("LIKE ") {
                    let pureValue = val.replacingOccurrences(of: "LIKE ", with: "")
                    sql += " AND \(pivot.table).\(col) LIKE ?"
                    self.arguments.append(pureValue)
                } else {
                    sql += " AND \(pivot.table).\(col) = ?"
                    self.arguments.append(val)
                }
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

// MARK: Performance
extension QueryBuilder {
    internal func performEagerLoading(on models: inout [T]) throws {
        guard let firstModel = models.first else { return }
        let parentIds = models.compactMap { $0.idValue }
        if parentIds.isEmpty { return }

        let templateMirror = Mirror(reflecting: firstModel)

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
            }), let relation = child.value as? BoltRelation else { continue }

            try openAndLoad(relation.relatedModelType, models: &models, relation: relation, relationName: relationName, parentIds: parentIds, nested: nestedPaths)
        }
    }

    private func openAndLoad<M: Model>(_ type: M.Type, models: inout [T], relation: BoltRelation, relationName: String, parentIds: [Int64], nested: [String]) throws {
        guard let pivot = relation.pivotConfig(parentTable: T.tableName) else { return }
        
        let pivotDatabase = T.databaseName
        let isSingleDatabase = (M.databaseName == pivotDatabase)

        if isSingleDatabase {
            try performJoinLoad(type, models: &models, pivot: pivot, relation: relation, relationName: relationName, parentIds: parentIds, nested: nested)
        } else {
            try performManualLoad(type, models: &models, pivot: pivot, relation: relation, relationName: relationName, parentIds: parentIds, nested: nested, pivotDB: pivotDatabase)
        }
    }

    private func performJoinLoad<M: Model>(_ type: M.Type, models: inout [T], pivot: (table: String, parentKey: String, relatedKey: String), relation: BoltRelation, relationName: String, parentIds: [Int64], nested: [String]) throws {
        let placeholders = String(repeating: "?,", count: parentIds.count).dropLast()
        var args: [Any] = parentIds
        
        var sql = "SELECT `\(M.tableName)`.*, `\(pivot.table)`.`\(pivot.parentKey)` AS pivot_parent_id " +
                  "FROM `\(M.tableName)` INNER JOIN `\(pivot.table)` ON `\(M.tableName)`.id = `\(pivot.table)`.`\(pivot.relatedKey)` " +
                  "WHERE `\(pivot.table)`.`\(pivot.parentKey)` IN (\(placeholders))"
        
        for (col, val) in relation.extraConditions(parentTable: T.tableName) {
            let op = val.hasPrefix("LIKE ") ? "LIKE" : "="
            sql += " AND `\(pivot.table)`.`\(col)` \(op) ?"
            args.append(val.replacingOccurrences(of: "LIKE ", with: ""))
        }

        let driver = try BoltSpark.driver(for: M.databaseName)
        let rawData = try driver.fetch(sql, arguments: args)
        
        try mapAndDistribute(rawData: rawData, models: &models, relationName: relationName, type: M.self, pivotKey: "pivot_parent_id", nested: nested)
    }
    
    private func performManualLoad<M: Model>(_ type: M.Type, models: inout [T], pivot: (table: String, parentKey: String, relatedKey: String), relation: BoltRelation, relationName: String, parentIds: [Int64], nested: [String], pivotDB: String) throws {
        let placeholders = String(repeating: "?,", count: parentIds.count).dropLast()
        var pivotSql = "SELECT * FROM `\(pivot.table)` WHERE `\(pivot.parentKey)` IN (\(placeholders))"
        var pivotArgs: [Any] = parentIds
        
        for (col, val) in relation.extraConditions(parentTable: T.tableName) {
            let op = val.hasPrefix("LIKE ") ? "LIKE" : "="
            pivotSql += " AND `\(col)` \(op) ?"
            pivotArgs.append(val.replacingOccurrences(of: "LIKE ", with: ""))
        }
        
        let pivotDriver = try BoltSpark.driver(for: pivotDB)
        let pivotRows = try pivotDriver.fetch(pivotSql, arguments: pivotArgs)
        if pivotRows.isEmpty { return }

        let relatedIds = Array(Set(pivotRows.compactMap { ($0[pivot.relatedKey] as? Int64) ?? ($0[pivot.relatedKey] as? Int).map { Int64($0) } }))
        let relatedPlaceholders = String(repeating: "?,", count: relatedIds.count).dropLast()
        let relatedSql = "SELECT * FROM `\(M.tableName)` WHERE id IN (\(relatedPlaceholders))"
        
        let modelDriver = try BoltSpark.driver(for: M.databaseName)
        let modelRows = try modelDriver.fetch(relatedSql, arguments: relatedIds)
        let allRelatedModels = try ModelMapper.map(modelRows, to: M.self)

        try distributeManualResults(pivotRows: pivotRows, allRelatedModels: allRelatedModels, models: &models, relationName: relationName, pivotParentKey: pivot.parentKey, pivotRelatedKey: pivot.relatedKey, nested: nested)
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

    // MARK: - Unified Distribution Helpers
    private func mapAndDistribute<M: Model>(rawData: [[String: Any]], models: inout [T], relationName: String, type: M.Type, pivotKey: String, nested: [String]) throws {
        guard let firstModel = models.first else { return }
        let relationLabel = Mirror(reflecting: firstModel).children.first { $0.label?.replacingOccurrences(of: "_", with: "") == relationName }?.label

        for i in 0..<models.count {
            let pid = models[i].idValue
            let mirror = Mirror(reflecting: models[i])
            
            if let label = relationLabel, let child = mirror.children.first(where: { $0.label == label }),
               let modelRel = child.value as? BoltRelation {
                
                let filteredRaw = rawData.filter { row in
                    let dbId = (row[pivotKey] as? Int64) ?? (row[pivotKey] as? Int).map { Int64($0) }
                    return dbId == pid
                }
                var mapped = try ModelMapper.map(filteredRaw, to: M.self)
                
                if !nested.isEmpty && !mapped.isEmpty {
                    var erased = mapped as [any Model]
                    try eagerLoadNested(models: &erased, type: M.self, relations: nested)
                    mapped = erased.compactMap { $0 as? M }
                }
                
                modelRel.setRelationData(mapped)
            }
        }
    }

    private func distributeManualResults<M: Model>(pivotRows: [[String: Any]], allRelatedModels: [M], models: inout [T], relationName: String, pivotParentKey: String, pivotRelatedKey: String, nested: [String]) throws {
        guard let firstModel = models.first else { return }
        let relationLabel = Mirror(reflecting: firstModel).children.first { $0.label?.replacingOccurrences(of: "_", with: "") == relationName }?.label

        for i in 0..<models.count {
            let pid = models[i].idValue
            let mirror = Mirror(reflecting: models[i])
            
            if let label = relationLabel, let child = mirror.children.first(where: { $0.label == label }),
               let modelRel = child.value as? BoltRelation {
                
                let myRelatedIds = pivotRows.filter { row in
                    let dbId = (row[pivotParentKey] as? Int64) ?? (row[pivotParentKey] as? Int).map { Int64($0) }
                    return dbId == pid
                }.compactMap { ($0[pivotRelatedKey] as? Int64) ?? ($0[pivotRelatedKey] as? Int).map { Int64($0) } }
                
                var myModels = allRelatedModels.filter { myRelatedIds.contains($0.idValue ?? -1) }
                
                if !nested.isEmpty && !myModels.isEmpty {
                    var erased = myModels as [any Model]
                    try eagerLoadNested(models: &erased, type: M.self, relations: nested)
                    myModels = erased.compactMap { $0 as? M }
                }
                
                modelRel.setRelationData(myModels)
            }
        }
    }
}
