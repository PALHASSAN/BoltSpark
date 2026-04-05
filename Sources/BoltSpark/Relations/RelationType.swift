//
//  RelationType.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 25/09/1447 AH.
//

import Foundation

@propertyWrapper
public final class HasMany<Related: Model>: BoltRelation, Codable {
    public var wrappedValue: [Related] = []
    public var key: String = ""
    public var relatedModelType: any Model.Type { Related.self }
    
    public func guessKey(parentTable: String) -> String {
        return key.isEmpty ? "\(parentTable.singularized.toSnakeCase())_id" : key
    }
    
    public init(wrappedValue: [Related] = [], key: String = "") {
        self.wrappedValue = wrappedValue
        self.key = key
    }
    
    public func setRelationData(_ data: Any) { self.wrappedValue = (data as? [Related]) ?? [] }
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = (try? container.decode([Related].self)) ?? []
        self.key = ""
    }
    public func encode(to encoder: Encoder) throws {}
}

@propertyWrapper
public final class HasOne<Related: Model>: BoltRelation, Codable {
    public var wrappedValue: Related?
    public var key: String = ""
    public var relatedModelType: any Model.Type { Related.self }
    
    public init(wrappedValue: Related? = nil, key: String = "") {
        self.wrappedValue = wrappedValue
        self.key = key
    }
    
    public func guessKey(parentTable: String) -> String {
        return key.isEmpty ? "\(parentTable.singularized.toSnakeCase())_id" : key
    }
    
    public func setRelationData(_ data: Any) { self.wrappedValue = data as? Related }
    public init(from decoder: Decoder) throws { self.wrappedValue = nil; self.key = "" }
    public func encode(to encoder: Encoder) throws {}
}

@propertyWrapper
public final class BelongsTo<Related: Model>: BoltRelation, Codable {
    public var wrappedValue: Related?
    public var key: String = ""
    public var relatedModelType: any Model.Type { Related.self }
    
    public func guessKey(parentTable: String) -> String {
        return "id"
    }
    
    public init(wrappedValue: Related? = nil, key: String = "") {
        self.wrappedValue = wrappedValue
        self.key = key
    }
    
    public func setRelationData(_ data: Any) { self.wrappedValue = data as? Related }
    public init(from decoder: Decoder) throws { self.wrappedValue = nil; self.key = "" }
    public func encode(to encoder: Encoder) throws {}
}

@propertyWrapper
public final class BelongsToMany<Related: Model>: BoltRelation, Codable {
    public var wrappedValue: [Related]
    public var key: String
    public var foreignKey: String?
    public var relatedKey: String?
    public var pivotDatabase: String?

    public var relatedModelType: any Model.Type { Related.self }

    public init(wrappedValue: [Related] = [], pivotTable: String = "", foreignKey: String? = nil, relatedKey: String? = nil, pivotDatabase: String? = nil) {
        self.wrappedValue = wrappedValue
        self.key = pivotTable
        self.foreignKey = foreignKey
        self.relatedKey = relatedKey
        self.pivotDatabase = pivotDatabase
    }

    public func pivotConfig(parentTable: String) -> (table: String, parentKey: String, relatedKey: String, database: String)? {
        let actualTable: String
        if !key.isEmpty {
            actualTable = key
        } else {
            let pTable = parentTable.singularized.toSnakeCase()
            let rTable = Related.tableName.singularized.toSnakeCase()
            actualTable = [pTable, rTable].sorted().joined(separator: "_")
        }
        
        let pk = foreignKey ?? "\(parentTable.singularized.toSnakeCase())_id"
        let rk = relatedKey ?? "\(Related.tableName.singularized.toSnakeCase())_id"
        let db = pivotDatabase ?? actualTable
        
        return (table: actualTable, parentKey: pk, relatedKey: rk, database: db)
    }
    
    public func restoreConfig(from original: BoltRelation) {
        guard let originalRelation = original as? BelongsToMany<Related> else { return }
        
        self.key = originalRelation.key
        self.foreignKey = originalRelation.foreignKey
        self.relatedKey = originalRelation.relatedKey
        self.pivotDatabase = originalRelation.pivotDatabase
    }
    
    public func guessKey(parentTable: String) -> String { return "id" }
    public func setRelationData(_ data: Any) { self.wrappedValue = (data as? [Related]) ?? [] }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = (try? container.decode([Related].self)) ?? []
        self.key = ""
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

@propertyWrapper
public final class HasManyThrough<Related: Model>: BoltRelation, Codable {
    public var wrappedValue: [Related] = []
    public var key: String = ""
    public var relatedModelType: any Model.Type { Related.self }
    public init(wrappedValue: [Related] = [], key: String = "") {
        self.wrappedValue = wrappedValue
        self.key = key
    }
    
    public func guessKey(parentTable: String) -> String {
        return key.isEmpty ? "\(parentTable.singularized.toSnakeCase())_id" : key
    }
    
    public func setRelationData(_ data: Any) { self.wrappedValue = (data as? [Related]) ?? [] }
    public init(from decoder: Decoder) throws { self.wrappedValue = []; self.key = "" }
    public func encode(to encoder: Encoder) throws {}
}

@propertyWrapper
public final class HasOneThrough<Related: Model>: BoltRelation, Codable {
    public var wrappedValue: Related?
    public var key: String = ""
    public var relatedModelType: any Model.Type { Related.self }
    public init(wrappedValue: Related? = nil, key: String = "") {
        self.wrappedValue = wrappedValue
        self.key = key
    }
    
    public func guessKey(parentTable: String) -> String {
        return key.isEmpty ? "\(parentTable.singularized)_id" : key
    }
    
    public func setRelationData(_ data: Any) { self.wrappedValue = data as? Related }
    public init(from decoder: Decoder) throws { self.wrappedValue = nil; self.key = "" }
    public func encode(to encoder: Encoder) throws {}
}

@propertyWrapper
public final class MorphMany<Related: Model>: BoltRelation, Codable {
    public var wrappedValue: [Related] = []
    public var key: String
    public var relatedModelType: any Model.Type { Related.self }
    
    public init(wrappedValue: [Related] = [], _ name: String = "") {
        self.wrappedValue = wrappedValue
        self.key = name
    }
    
    public func guessKey(parentTable: String) -> String {
        let finalKey = key.isEmpty ? "modelable" : key.toSnakeCase()
        return "\(finalKey)_id"
    }

    public func extraConditions(parentTable: String) -> [String: String] {
        let finalKey = key.isEmpty ? "modelable" : key.toSnakeCase()
        let targetType = parentTable.singularized.capitalized
        return ["\(finalKey)_type": "LIKE %\(targetType)%"]
    }
    
    public func setRelationData(_ data: Any) { self.wrappedValue = (data as? [Related]) ?? [] }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = (try? container.decode([Related].self)) ?? []
        self.key = ""
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

@propertyWrapper
public final class MorphOne<Related: Model>: BoltRelation, Codable {
    public var wrappedValue: Related?
    public var key: String
    public var relatedModelType: any Model.Type { Related.self }
    public init(wrappedValue: Related? = nil, _ name: String) {
        self.wrappedValue = wrappedValue
        self.key = name
    }
    
    public func guessKey(parentTable: String) -> String {
        return "\(key)_id"
    }
    public func extraConditions(parentTable: String) -> [String: String] {
        return ["\(key)_type": "LIKE %\(parentTable.singularized.capitalized)"]
    }
    
    public func setRelationData(_ data: Any) { self.wrappedValue = data as? Related }
    public init(from decoder: Decoder) throws { self.wrappedValue = nil; self.key = "" }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

@propertyWrapper
public final class MorphTo<Related: Model>: BoltRelation, Codable {
    public var wrappedValue: Related?
    public var key: String
    public var relatedModelType: any Model.Type { Related.self }
    
    public init(wrappedValue: Related? = nil, _ name: String) {
        self.wrappedValue = wrappedValue
        self.key = name
    }
    
    public func guessKey(parentTable: String) -> String {
        return "\(key)_id"
    }
    
    public func setRelationData(_ data: Any) { self.wrappedValue = data as? Related }
    public init(from decoder: Decoder) throws { self.wrappedValue = nil; self.key = "" }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

@propertyWrapper
public final class MorphToMany<Related: Model>: BoltRelation, Codable {
    public var wrappedValue: [Related] = []
    public var key: String
    public var pivotTable: String
    public var relatedModelType: any Model.Type { Related.self }
    public var pivotDatabase: String?

    public init(wrappedValue: [Related] = [], pivotTable: String, name: String) {
        self.wrappedValue = wrappedValue
        self.pivotTable = pivotTable
        self.key = name
    }

    public func guessKey(parentTable: String) -> String { return "id" }
    public func extraConditions(parentTable: String) -> [String: String] {
        let finalKey = self.key.isEmpty ? "model" : self.key
        let targetType = String(describing: Related.self)
        return ["\(finalKey)_type": "LIKE %\(targetType)%"]
    }

    public func pivotConfig(parentTable: String) -> (table: String, parentKey: String, relatedKey: String, database: String)? {
        let table = self.pivotTable.isEmpty ? "\(parentTable.singularized)_links" : self.pivotTable
        let finalKey = self.key.isEmpty ? "model" : self.key
        
        let database = self.pivotDatabase ?? table
        
        return (
            table: table,
            parentKey: "\(parentTable.singularized)_id",
            relatedKey: "\(finalKey)_id",
            database: database
        )
    }

    public func setRelationData(_ data: Any) { self.wrappedValue = (data as? [Related]) ?? [] }
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = (try? container.decode([Related].self)) ?? []
        self.key = ""
        self.pivotTable = ""
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

@propertyWrapper
public final class MorphedByMany<Related: Model>: BoltRelation, Codable {
    public var wrappedValue: [Related] = []
    public var key: String
    public var pivotTable: String?
    
    public var relatedModelType: any Model.Type { Related.self }
    public init(wrappedValue: [Related] = [], pivotTable: String? = nil, _ name: String) {
        self.wrappedValue = wrappedValue
        self.pivotTable = pivotTable
        self.key = name
    }
    
    public func guessKey(parentTable: String) -> String {
        return "id"
    }
    public func extraConditions(parentTable: String) -> [String: String] {
        return ["\(key)_type": "LIKE %\(Related.tableName.singularized.capitalized)"]
    }
    
    public func pivotConfig(parentTable: String) -> (table: String, parentKey: String, relatedKey: String)? {
        let table = self.pivotTable ?? "\(Related.tableName.singularized)ables"
        let finalKey = self.key.isEmpty ? "model" : self.key
        
        let parentKey = "\(finalKey)_id"
        let relatedKey = "\(Related.tableName.singularized)_id"
                
        return (table: table, parentKey: parentKey, relatedKey: relatedKey)
    }
    
    public func setRelationData(_ data: Any) { self.wrappedValue = (data as? [Related]) ?? [] }
    public init(from decoder: Decoder) throws { self.wrappedValue = []; self.key = "" }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}
