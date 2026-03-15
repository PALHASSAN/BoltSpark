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
    
    public init() {}
    public func setRelationData(_ data: Any) { self.wrappedValue = (data as? [Related]) ?? [] }
    public init(from decoder: Decoder) throws {}
    public func encode(to encoder: Encoder) throws {}
}

@propertyWrapper
public final class HasOne<Related: Model>: BoltRelation, Codable {
    public var wrappedValue: Related?
    public var key: String = ""
    public var relatedModelType: any Model.Type { Related.self }
    public init() {}
    
    public func guessKey(parentTable: String) -> String {
        return key.isEmpty ? "\(parentTable.singularized)_id" : key
    }
    
    public func setRelationData(_ data: Any) { self.wrappedValue = data as? Related }
    public init(from decoder: Decoder) throws {}
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
    
    public init() {}
    public func setRelationData(_ data: Any) { self.wrappedValue = data as? Related }
    public init(from decoder: Decoder) throws {}
    public func encode(to encoder: Encoder) throws {}
}

@propertyWrapper
public final class BelongsToMany<Related: Model>: BoltRelation, Codable {
    public var wrappedValue: [Related] = []
    public var key: String = ""
    public var relatedModelType: any Model.Type { Related.self }
    public init() {}
    
    public func guessKey(parentTable: String) -> String {
        return "id"
    }
    
    public func pivotConfig(parentTable: String) -> (table: String, parentKey: String, relatedKey: String)? {
        (table: key, parentKey: "\(parentTable.singularized)_id", relatedKey: "\(Related.tableName.singularized)_id")
    }
    
    public func setRelationData(_ data: Any) { self.wrappedValue = (data as? [Related]) ?? [] }
    public init(from decoder: Decoder) throws {}
    public func encode(to encoder: Encoder) throws {}
}

@propertyWrapper
public final class HasManyThrough<Related: Model>: BoltRelation, Codable {
    public var wrappedValue: [Related] = []
    public var key: String = ""
    public var relatedModelType: any Model.Type { Related.self }
    public init() {}
    
    public func guessKey(parentTable: String) -> String {
        return key.isEmpty ? "\(parentTable.singularized)_id" : key
    }
    
    public func setRelationData(_ data: Any) { self.wrappedValue = (data as? [Related]) ?? [] }
    public init(from decoder: Decoder) throws {}
    public func encode(to encoder: Encoder) throws {}
}

@propertyWrapper
public final class HasOneThrough<Related: Model>: BoltRelation, Codable {
    public var wrappedValue: Related?
    public var key: String = ""
    public var relatedModelType: any Model.Type { Related.self }
    public init() {}
    
    public func guessKey(parentTable: String) -> String {
        return key.isEmpty ? "\(parentTable.singularized)_id" : key
    }
    
    public func setRelationData(_ data: Any) { self.wrappedValue = data as? Related }
    public init(from decoder: Decoder) throws {}
    public func encode(to encoder: Encoder) throws {}
}

@propertyWrapper
public final class MorphMany<Related: Model>: BoltRelation, Codable {
    public var wrappedValue: [Related] = []
    public var key: String
    public var relatedModelType: any Model.Type { Related.self }
    public init(_ name: String) { self.key = name }
    
    public func guessKey(parentTable: String) -> String {
        return "\(key)_id"
    }
    public func extraConditions(parentTable: String) -> [String: Any] {
        return ["\(key)_type": parentTable.singularized]
    }
    
    public func setRelationData(_ data: Any) { self.wrappedValue = (data as? [Related]) ?? [] }
    public init(from decoder: Decoder) throws { self.key = "" }
    public func encode(to encoder: Encoder) throws {}
}

@propertyWrapper
public final class MorphOne<Related: Model>: BoltRelation, Codable {
    public var wrappedValue: Related?
    public var key: String
    public var relatedModelType: any Model.Type { Related.self }
    public init(_ name: String) { self.key = name }
    
    public func guessKey(parentTable: String) -> String {
        return "\(key)_id"
    }
    public func extraConditions(parentTable: String) -> [String: Any] {
        return ["\(key)_type": parentTable.singularized]
    }
    
    public func setRelationData(_ data: Any) { self.wrappedValue = data as? Related }
    public init(from decoder: Decoder) throws { self.key = "" }
    public func encode(to encoder: Encoder) throws {}
}

@propertyWrapper
public final class MorphTo<Related: Model>: BoltRelation, Codable {
    public var wrappedValue: Related?
    public var key: String
    public var relatedModelType: any Model.Type { Related.self }
    public init(_ name: String) { self.key = name }
    
    public func guessKey(parentTable: String) -> String {
        return "id"
    }
    
    public func setRelationData(_ data: Any) { self.wrappedValue = data as? Related }
    public init(from decoder: Decoder) throws { self.key = "" }
    public func encode(to encoder: Encoder) throws {}
}

@propertyWrapper
public final class MorphToMany<Related: Model>: BoltRelation, Codable {
    public var wrappedValue: [Related] = []
    public var key: String
    public var relatedModelType: any Model.Type { Related.self }
    public init(_ name: String) { self.key = name }
    
    public func guessKey(parentTable: String) -> String {
        return "id"
    }
    public func extraConditions(parentTable: String) -> [String: Any] {
        return ["\(key)_type": parentTable.singularized]
    }
    
    public func pivotConfig(parentTable: String) -> (table: String, parentKey: String, relatedKey: String)? {
        (table: "\(key)s", parentKey: "\(key)_id", relatedKey: "\(Related.tableName.singularized)_id")
    }
    
    public func setRelationData(_ data: Any) { self.wrappedValue = (data as? [Related]) ?? [] }
    public init(from decoder: Decoder) throws { self.key = "" }
    public func encode(to encoder: Encoder) throws {}
}

@propertyWrapper
public final class MorphedByMany<Related: Model>: BoltRelation, Codable {
    public var wrappedValue: [Related] = []
    public var key: String
    public var relatedModelType: any Model.Type { Related.self }
    public init(_ name: String) { self.key = name }
    
    public func guessKey(parentTable: String) -> String {
        return "id"
    }
    public func extraConditions(parentTable: String) -> [String: Any] {
        return ["\(key)_type": Related.tableName.singularized]
    }
    
    public func pivotConfig(parentTable: String) -> (table: String, parentKey: String, relatedKey: String)? {
        (table: "\(key)s", parentKey: "\(parentTable.singularized)_id", relatedKey: "\(key)_id")
    }
    
    public func setRelationData(_ data: Any) { self.wrappedValue = (data as? [Related]) ?? [] }
    public init(from decoder: Decoder) throws { self.key = "" }
    public func encode(to encoder: Encoder) throws {}
}
