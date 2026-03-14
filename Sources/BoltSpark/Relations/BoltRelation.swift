//
//  Relation.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 25/09/1447 AH.
//

import Foundation

public protocol BoltRelation {
    var key: String { get }
    
    var relatedModelType: any Model.Type { get }
    func setRelationData(_ data: Any)
    
    func guessKey(parentTable: String) -> String
}
