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
        return key.isEmpty ? "\(Related.tableName.singularized)_id" : key
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
    public func setRelationData(_ data: Any) { self.wrappedValue = (data as? [Related]) ?? [] }
    public init(from decoder: Decoder) throws { self.key = "" }
    public func encode(to encoder: Encoder) throws {}
}
