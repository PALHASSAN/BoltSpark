//
//  Relations.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 25/09/1447 AH.
//

import Foundation

public protocol Relations {
    associatedtype RelatedModel: Model
    
    func query() -> QueryBuilder<RelatedModel>
}
