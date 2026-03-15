//
//  ModelRelation.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 25/09/1447 AH.
//

import Foundation

extension Model {
    
    // MARK: - One-to-Many
    public func hasMany<T: Model>(foreignKey: String? = nil, primaryKey: String = "id") -> HasMany<T> {
        let relation = HasMany<T>()
        relation.key = foreignKey ?? "\(String(describing: Self.self).toSnakeCase().singularized)_id"
        return relation
    }
    
    // MARK: - One-to-One
    public func hasOne<T: Model>(foreignKey: String? = nil, primaryKey: String = "id") -> HasOne<T> {
        let relation = HasOne<T>()
        relation.key = foreignKey ?? "\(String(describing: Self.self).toSnakeCase().singularized)_id"
        return relation
    }
    
    // MARK: - BelongsTo (Inverse)
    public func belongsTo<T: Model>(foreignKey: String? = nil) -> BelongsTo<T> {
        let relation = BelongsTo<T>()
        relation.key = foreignKey ?? "\(String(describing: T.self).toSnakeCase().singularized)_id"
        return relation
    }
    
    // MARK: - Many-to-Many
    public func belongsToMany<T: Model>(
        pivot: String? = nil,
        foreignPivotKey: String? = nil,
        relatedPivotKey: String? = nil
    ) -> BelongsToMany<T> {
        return BelongsToMany<T>(
            pivotTable: pivot ?? "",
            foreignKey: foreignPivotKey,
            relatedKey: relatedPivotKey
        )
    }
    
    // MARK: - Relationships Through
    public func hasManyThrough<T: Model, Through: Model>(
        through: Through.Type,
        firstKey: String? = nil,
        secondKey: String? = nil
    ) -> HasManyThrough<T> {
        let relation = HasManyThrough<T>()
        relation.key = secondKey ?? "\(String(describing: Through.self).toSnakeCase().singularized)_id"
        return relation
    }
    
    public func hasOneThrough<T: Model, Through: Model>(
        through: Through.Type,
        firstKey: String? = nil,
        secondKey: String? = nil
    ) -> HasOneThrough<T> {
        let relation = HasOneThrough<T>()
        relation.key = secondKey ?? "\(String(describing: Through.self).toSnakeCase().singularized)_id"
        return relation
    }
    
    // MARK: - Polymorphic (Morph)
    public func morphMany<T: Model>(name: String) -> MorphMany<T> {
        return MorphMany<T>(name)
    }
    
    public func morphOne<T: Model>(name: String) -> MorphOne<T> {
        return MorphOne<T>(name)
    }
    
    public func morphTo<T: Model>(name: String) -> MorphTo<T> {
        return MorphTo<T>(name)
    }
    
    public func morphToMany<T: Model>(name: String, pivotTable: String) -> MorphToMany<T> {
        return MorphToMany<T>(pivotTable: pivotTable, name: name)
    }
    
    public func morphedByMany<T: Model>(name: String, table: String? = nil) -> MorphedByMany<T> {
        let relation = MorphedByMany<T>(name)
        if let table = table {
            relation.key = table
        }
        return relation
    }
}
