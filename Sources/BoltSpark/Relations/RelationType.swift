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
        return key.isEmpty ? "\(parentTable.singularized)_id" : key
    }
    
    public init(wrappedValue: [Related] = [], key: String = "") {
        self.wrappedValue = wrappedValue
        self.key = key
    }
    
    public func setRelationData(_ data: Any) { self.wrappedValue = (data as? [Related]) ?? [] }
    public init(from decoder: Decoder) throws { self.wrappedValue = []; self.key = "" }
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
        return key.isEmpty ? "\(parentTable.singularized)_id" : key
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
    
    public var relatedModelType: any Model.Type { Related.self }

    public init(wrappedValue: [Related] = [], pivotTable: String = "", foreignKey: String? = nil, relatedKey: String? = nil) {
        self.wrappedValue = wrappedValue
        self.key = pivotTable
        self.foreignKey = foreignKey
        self.relatedKey = relatedKey
    }

    public func pivotConfig(parentTable: String) -> (table: String, parentKey: String, relatedKey: String)? {
        let actualTable: String
        if !key.isEmpty {
            actualTable = key
        } else {
            let p = parentTable.singularized
            let r = Related.tableName.singularized
            actualTable = [p, r].sorted().joined(separator: "_")
        }
        
        let pk = foreignKey ?? "\(parentTable.singularized)_id"
        let rk = relatedKey ?? "\(Related.tableName.singularized)_id"
        
        return (table: actualTable, parentKey: pk, relatedKey: rk)
    }
    
    public func guessKey(parentTable: String) -> String { return "id" }
    public func setRelationData(_ data: Any) { self.wrappedValue = (data as? [Related]) ?? [] }
    
    public init(from decoder: Decoder) throws {
        self.wrappedValue = []
        self.key = ""
        self.foreignKey = nil
        self.relatedKey = nil
    }
    public func encode(to encoder: Encoder) throws {}
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
        return key.isEmpty ? "\(parentTable.singularized)_id" : key
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
    
    public init(wrappedValue: [Related] = [], _ name: String) {
        self.wrappedValue = wrappedValue
        self.key = name
    }
    public func guessKey(parentTable: String) -> String {
        return "\(key)_id"
    }
    public func extraConditions(parentTable: String) -> [String: String] {
        return ["\(key)_type": "LIKE %\(parentTable.singularized.capitalized)"]
    }
    
    public func setRelationData(_ data: Any) { self.wrappedValue = (data as? [Related]) ?? [] }
    public init(from decoder: Decoder) throws { self.wrappedValue = []; self.key = "" }
    public func encode(to encoder: Encoder) throws {}
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
    public func encode(to encoder: Encoder) throws {}
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
        return "id"
    }
    
    public func setRelationData(_ data: Any) { self.wrappedValue = data as? Related }
    public init(from decoder: Decoder) throws { self.wrappedValue = nil; self.key = "" }
    public func encode(to encoder: Encoder) throws {}
}

@propertyWrapper
public final class MorphToMany<Related: Model>: BoltRelation, Codable {
    public var wrappedValue: [Related] = []
    public var key: String
    public var pivotTable: String
    public var relatedModelType: any Model.Type { Related.self }

    public init(wrappedValue: [Related] = [], pivotTable: String, name: String) {
        self.wrappedValue = wrappedValue
        self.pivotTable = pivotTable
        self.key = name
    }

    public func guessKey(parentTable: String) -> String { return "id" }
    public func extraConditions(parentTable: String) -> [String: String] {
        return ["\(key)_type": "LIKE %\(parentTable.singularized.capitalized)"]
    }

    public func pivotConfig(parentTable: String) -> (table: String, parentKey: String, relatedKey: String)? {
        let parentKey = "\(key)_id"
        let relatedKey = "\(Related.tableName.singularized)_id"
        return (table: pivotTable, parentKey: parentKey, relatedKey: relatedKey)
    }

    public func setRelationData(_ data: Any) { self.wrappedValue = (data as? [Related]) ?? [] }
    public init(from decoder: Decoder) throws { self.wrappedValue = []; self.key = ""; self.pivotTable = "" }
    public func encode(to encoder: Encoder) throws {}
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
        return ["\(key)_type": "LIKE %\(parentTable.singularized.capitalized)"]
    }
    
    public func pivotConfig(parentTable: String) -> (table: String, parentKey: String, relatedKey: String)? {
        let table = self.pivotTable ?? "\(Related.tableName.singularized)_links"
        let parentKey = "\(key)_id"
        let relatedKey = "\(Related.tableName.singularized)_id"
                
        return (table: table, parentKey: parentKey, relatedKey: relatedKey)
    }
    
    public func setRelationData(_ data: Any) { self.wrappedValue = (data as? [Related]) ?? [] }
    public init(from decoder: Decoder) throws { self.wrappedValue = []; self.key = "" }
    public func encode(to encoder: Encoder) throws {}
}
