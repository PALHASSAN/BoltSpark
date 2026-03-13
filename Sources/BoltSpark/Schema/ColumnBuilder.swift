//
//  ColumnBuilder.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 22/09/1447 AH.
//

import Foundation
import GRDB

public class ColumnBuilder {
    let name: String
    let type: Database.ColumnType
    var isNullable: Bool = false
    var isUnique: Bool = false
    var defaultValue: (any DatabaseValueConvertible)?
    
    init(name: String, type: Database.ColumnType) {
        self.name = name
        self.type = type
    }
    
    @discardableResult
    public func nullable() -> Self {
        self.isNullable = true
        return self
    }
    
    @discardableResult
    public func unique() -> Self {
        self.isUnique = true
        return self
    }
    
    @discardableResult
    public func defaults(to value: any DatabaseValueConvertible) -> Self {
        self.defaultValue = value
        return self
    }
}
