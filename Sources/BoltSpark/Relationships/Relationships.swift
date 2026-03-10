//
//  Relationships.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 21/09/1447 AH.
//

import GRDB

extension Model where Self: TableRecord {
    public static func belongsTo<Parent: Model>(_ parent: Parent.Type, foreignKey: String) -> BelongsToAssociation<Self, Parent> {
        return self.belongsTo(parent, key: foreignKey)
    }
    
    public static func hasOne<Child: Model>(_ child: Child.Type, foreignKey: String) -> HasOneAssociation<Self, Child> {
        return self.hasOne(child, key: foreignKey)
    }
    
    public static func hasMany<Child: Model>(_ child: Child.Type, foreignKey: String) -> HasManyAssociation<Self, Child> {
        return self.hasMany(child, key: foreignKey)
    }
    
    public static func belongsToMany<Target: Model>(
        _ target: Target.Type,
        through pivot: String,
        foreginKey: String,
        relatedKey: String
    ) -> HasManyThroughAssociation<Self, Target> {
        let pivotTable = Table(pivot)
        let associationToPivot = self.hasMany(pivotTable, using: ForeignKey([foreginKey]))
        
        let associationToTarget = pivotTable.belongsTo(target, using: ForeignKey([relatedKey]))
        return self.hasMany(target, through: associationToPivot, using: associationToTarget)
    }
    
    public static func morphMany<Child: Model>(_ child: Child.Type, name: String) -> HasManyAssociation<Self, Child> {
        return self.hasMany(child, key: "\(name)_id")
            .filter(Column("\(name)_type") == self.tableName)
    }
    
    public static func hasManyThrough<Intermediate: Model, Target: Model>(
        _ target: Target.Type,
        through intermediate: Intermediate.Type,
        foreginKey: String,
        relatedKey: String
    ) -> HasManyThroughAssociation<Self, Target> {
        
        let toIntermediate = self.hasMany(intermediate, using: ForeignKey([foreginKey]))
        
        let toTarget = intermediate.hasMany(target, using: ForeignKey([relatedKey]))
        
        return self.hasMany(target, through: toIntermediate, using: toTarget)
    }
    
    public static func morphOne<Child: Model>(_ child: Child.Type, name: String) -> HasOneAssociation<Self, Child> {
        return self.hasOne(child, key: "\(name)_id")
            .filter(Column("\(name)_type") == self.tableName)
    }
    
    public static func hasOneThrough<Intermediate: Model, Target: Model>(
        _ target: Target.Type,
        through intermediate: Intermediate.Type,
        foreignKey: String,
        relatedKey: String
    ) -> HasOneThroughAssociation<Self, Target> {
        
        let toIntermediate = self.hasOne(intermediate, using: ForeignKey([foreignKey]))
        let toTarget = intermediate.hasOne(target, using: ForeignKey([relatedKey]))
        
        return self.hasOne(target, through: toIntermediate, using: toTarget)
    }
    
    public static func morphTo<Target: Model>(_ target: Target.Type, name: String) -> BelongsToAssociation<Self, Target> {
        return self.belongsTo(target, key: "\(name)_id")
            .filter(Column("\(name)_type") == target.tableName)
    }
}
