//
//  Relation.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 25/09/1447 AH.
//

import Foundation

public protocol BoltRelation {
    var key: String { get set }
    
    var relatedModelType: any Model.Type { get }
    func setRelationData(_ data: Any)
    
    func guessKey(parentTable: String) -> String
    func extraConditions(parentTable: String) -> [String: String]
    
    func pivotConfig(parentTable: String) -> (table: String, parentKey: String, relatedKey: String, database: String)?
    
    func restoreConfig(from original: BoltRelation)
}

extension BoltRelation {
    public func extraConditions(parentTable: String) -> [String: String] { return [:] }
    public func pivotConfig(parentTable: String) -> (table: String, parentKey: String, relatedKey: String, database: String)? { nil }
    public func restoreConfig(from original: BoltRelation) {}
}
