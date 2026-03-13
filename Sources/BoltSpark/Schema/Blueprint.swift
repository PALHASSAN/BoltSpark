//
//  Blueprint.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 21/09/1447 AH.
//

import Foundation
import GRDB

extension ColumnDefinition {
    @discardableResult
    public func nullable() -> Self {
        return self
    }
}

public class Blueprint {
    var definition: TableDefinition
    private var columnRequests: [ColumnBuilder] = []
    var pendingIndexes: [(columns: [String], name: String?)] = []
    
    init(_ definition: TableDefinition) {
        self.definition = definition
    }
    
    private func addColumn(_ name: String, _ type: Database.ColumnType) -> ColumnBuilder {
        let builder = ColumnBuilder(name: name, type: type)
        columnRequests.append(builder)
        return builder
    }
    
    
    public class ForeignKeyDefinition {
        let table: String
        let column: String
        
        var onDeleteAction: DatabaseValueConvertible?
        var onUpdateAction: DatabaseValueConvertible?
        
        init(table: String, column: String) {
            self.table = table
            self.column = column
        }
        
        @discardableResult
        public func onDelete(_ action: String) -> Self {
            self.onDeleteAction = action // Like: CASCADE
            
            return self
        }
        
        @discardableResult
        public func onUpdate(_ action: String) -> Self {
            self.onUpdateAction = action // Like: CASCADE
            
            return self
        }
    }
    
    // MARK: - Primary Key
    public func id() {
        definition.autoIncrementedPrimaryKey("id")
    }
    
    public func primary(_ columns: [String]) {
        definition.primaryKey(columns)
    }
    
    // MARK: - Text & String
    @discardableResult
    public func string(_ name: String) -> ColumnDefinition {
        return definition.column(name, .text)
    }
    
    @discardableResult
    public func text(_ name: String) -> ColumnDefinition {
        return definition.column(name, .text)
    }
    
    // MARK: - Numbers
    @discardableResult
    public func integer(_ name: String) -> ColumnDefinition {
        return definition.column(name, .integer)
    }
    
    @discardableResult
    public func bigInteger(_ name: String) -> ColumnDefinition {
        return definition.column(name, .integer)
    }
    
    @discardableResult
    public func double(_ name: String) -> ColumnDefinition {
        return definition.column(name, .double)
    }
    
    @discardableResult
    public func decimal(_ name: String) -> ColumnDefinition {
        return definition.column(name, .double)
    }
    
    @discardableResult
    public func boolean(_ name: String) -> ColumnDefinition {
        return definition.column(name, .boolean)
    }
    
    // MARK: - Binary & Files
    @discardableResult
    public func binary(_ name: String) -> ColumnDefinition {
        return definition.column(name, .blob)
    }
    
    // MARK: - Dates
    @discardableResult
    public func date(_ name: String) -> ColumnDefinition {
        return definition.column(name, .date)
    }
    
    @discardableResult
    public func dateTime(_ name: String) -> ColumnDefinition {
        return definition.column(name, .datetime)
    }
    
    public func timestamps() {
        definition.column("created_at", .datetime).defaults(sql: "CURRENT_TIMESTAMP")
        definition.column("updated_at", .datetime).defaults(sql: "CURRENT_TIMESTAMP")
    }
    
    @discardableResult
    public func timestamp(_ name: String) -> ColumnDefinition {
        definition.column(name, .datetime)
    }
    
    public func softDelete() {
        self.addColumn("deleted_at", .datetime).nullable()
    }
    
    // MARK: - Indexes & Constraints
    public func unique(_ columns: [String]) {
        return definition.uniqueKey(columns)
    }
    
    public func index(_ columns: [String], name: String? = nil) {
        pendingIndexes.append((columns, name))
    }
    
    public func foreignId(_ name: String, references table: String, column: String = "id") {
        definition.column(name, .integer).references(table, column: column, onDelete: .cascade)
    }
    
    // MARK: - Polymorphic Columns (Morphs)
    public func morphs(_ name: String = "model") {
        definition.column("\(name)_id", .integer).notNull()
        definition.column("\(name)_type", .text).notNull()
        
        self.index(["\(name)_type", "\(name)_id"])
    }
    
    public func nullableMorphs(_ name: String = "model") {
        definition.column("\(name)_id", .integer)
        definition.column("\(name)_type", .text)
        
        self.index(["\(name)_type", "\(name)_id"])
    }
    
    func build() {
        for request in columnRequests {
            let col = definition.column(request.name, request.type)
            
            if !request.isNullable {
                col.notNull()
            }
            if request.isUnique { col.unique() }
            if let def = request.defaultValue { col.defaults(to: def) }
        }
    }
}
