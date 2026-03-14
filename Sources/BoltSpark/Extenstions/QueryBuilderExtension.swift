//
//  QueryBuilderExtension.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 23/09/1447 AH.
//

extension QueryBuilder {
    public func whereLike(_ column: String, _ pattern: String) -> Self {
        return self._whereRaw("\(column) LIKE ?", arguments: [pattern])
    }
    
    public func has(_ relation: String) -> Self {
        let foreignKey = "\(T.tableName.singularized)_id"
        let sql = "EXISTS (SELECT 1 FROM \(relation) WHERE \(relation).\(foreignKey) = \(T.tableName).id)"
        return self._whereRaw(sql)
    }
    
    public func doesntHave(_ relation: String) -> Self {
        let foreignKey = "\(T.tableName.singularized)_id"
        let sql = "NOT EXISTS (SELECT 1 FROM \(relation) WHERE \(relation).\(foreignKey) = \(T.tableName).id)"
        return self._whereRaw(sql)
    }
    
    public func whereHas(_ related: String, closure: (QueryBuilder<T>) -> Void) -> Self {
        let foreignKey = "\(T.tableName.singularized)_id"
        let subQueryBuilder = QueryBuilder<T>(request: T.all(), database: self.database)
        closure(subQueryBuilder)
        
        var sql = "EXISTS (SELECT 1 FROM \(related) WHERE \(related).\(foreignKey) = \(T.tableName).id"
        if let condition = subQueryBuilder.assembledCondition {
            sql += " AND \(condition)"
        }
        sql += ")"
        
        return self._whereRaw(sql)
    }
    
    public func whereDoesntHave(_ related: String, closure: (QueryBuilder<T>) -> Void) -> Self {
        let foreignKey = "\(T.tableName.singularized)_id"
        let subQueryBuilder = QueryBuilder<T>(request: T.all(), database: self.database)
        closure(subQueryBuilder)
        
        var sql = "NOT EXISTS (SELECT 1 FROM \(related) WHERE \(related).\(foreignKey) = \(T.tableName).id"
        if let condition = subQueryBuilder.assembledCondition {
            sql += " AND \(condition)"
        }
        sql += ")"
        return self._whereRaw(sql)
    }
    
    public func paginate(page: Int = 1, perPage: Int = 15) throws -> Paginator<T> {
        let totalRecords = try self.count()
        let safePage = max(1, page)
        let offset = (safePage - 1) * perPage
        let data: [T] = try self.limit(perPage, offset: offset).get()
        return Paginator(data: data, total: totalRecords, perPage: perPage, currentPage: safePage)
    }
}
