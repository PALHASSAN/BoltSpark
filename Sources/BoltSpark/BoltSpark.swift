@_exported import LiveValidate
import Foundation
import GRDB

@attached(member, names: named(create), named(update), named(init), named(created_at), named(updated_at), named(deleted_at))
@attached(extension, conformances: Model)
public macro Model() = #externalMacro(module: "BoltSparkMacros", type: "ModelMacro")

extension HasManyAssociation: @unchecked @retroactive Sendable {}
extension BelongsToAssociation: @unchecked @retroactive Sendable {}
extension HasOneAssociation: @unchecked @retroactive Sendable {}

// MARK: - Relationship Macros
@attached(peer, names: prefixed(`$`))
@attached(accessor)
public macro BelongsTo<T: Model>(_ type: T.Type, foreignKey: String? = nil) = #externalMacro(module: "BoltSparkMacros", type: "RelationshipMacro")

@attached(peer, names: prefixed(`$`))
@attached(accessor)
public macro HasOne<T: Model>(_ type: T.Type, foreignKey: String? = nil) = #externalMacro(module: "BoltSparkMacros", type: "RelationshipMacro")

@attached(peer, names: prefixed(`$`))
@attached(accessor)
public macro HasMany<T: Model>(_ type: T.Type, foreignKey: String? = nil) = #externalMacro(module: "BoltSparkMacros", type: "RelationshipMacro")

@attached(peer, names: prefixed(`$`))
@attached(accessor)
public macro BelongsToMany<T: Model>(_ type: T.Type, through pivot: String, foreignKey: String? = nil, relatedKey: String? = nil) = #externalMacro(module: "BoltSparkMacros", type: "RelationshipMacro")

@attached(peer, names: prefixed(`$`))
@attached(accessor)
public macro HasManyThrough<Intermediate: Model, Target: Model>(_ target: Target.Type, through intermediate: Intermediate.Type, foreignKey: String? = nil, relatedKey: String? = nil) = #externalMacro(module: "BoltSparkMacros", type: "RelationshipMacro")

@attached(peer, names: prefixed(`$`))
@attached(accessor)
public macro HasOneThrough<Intermediate: Model, Target: Model>(_ target: Target.Type, through intermediate: Intermediate.Type, foreignKey: String, relatedKey: String) = #externalMacro(module: "BoltSparkMacros", type: "RelationshipMacro")

@attached(peer, names: prefixed(`$`))
@attached(accessor)
public macro MorphMany<T: Model>(_ type: T.Type, name: String) = #externalMacro(module: "BoltSparkMacros", type: "RelationshipMacro")

@attached(peer, names: prefixed(`$`))
@attached(accessor)
public macro MorphOne<T: Model>(_ type: T.Type, name: String) = #externalMacro(module: "BoltSparkMacros", type: "RelationshipMacro")

@attached(peer, names: prefixed(`$`))
@attached(accessor)
public macro MorphTo<T: Model>(_ type: T.Type, name: String) = #externalMacro(module: "BoltSparkMacros", type: "RelationshipMacro")

struct BoltSparkVerifier: DatabasePresenceVerifier {
    func count(table: String, column: String, value: String) async -> Int {
        return await (try? BoltSpark.db.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \(table) WHERE \(column) = ?", arguments: [value])
        }) ?? 0
    }
}

public enum BoltSpark {
    /// A lock to ensure thread-safe access to the database (Swift 6 safety)
    private static let lock = NSLock()
    
    /// Internal storage for the database connection
    nonisolated(unsafe) private static var _db: DatabaseWriter?
    
    /// The global accessor that models and query builders use internally
    public static var db: DatabaseWriter {
        lock.lock()
        defer { lock.unlock() }
        
        // 1. If the developer already provided a connection via setup(), use it.
        if let connection = _db {
            return connection
        }
        
        // 2. If no connection exists, initialize the default "Zero-Config" database.
        do {
            let folderURL = try FileManager.default
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let dbURL = folderURL.appendingPathComponent("boltspark.sqlite")
            
            // Using DatabasePool for high-performance concurrent reads
            let pool = try DatabasePool(path: dbURL.path)
            
#if DEBUG
            print("⚡️ BoltSpark: Database auto-initialized at: \(dbURL.path)")
#endif
            
            _db = pool
            Task { @MainActor in
                ValidateConfig.setup(engine: .custom(BoltSparkVerifier()))
            }
            return pool
        } catch {
            // If we can't create a database, the app cannot function.
            fatalError("⚡️ BoltSpark Error: Failed to auto-initialize database: \(error)")
        }
    }
    
    /// Optional manual setup if the developer wants to use a specific database or path
    /// - Parameter db: A DatabaseWriter instance (DatabaseQueue or DatabasePool)
    public static func setup(_ db: DatabaseWriter) {
        lock.lock()
        self._db = db
        lock.unlock()
        
        Task { @MainActor in
            ValidateConfig.setup(engine: .custom(BoltSparkVerifier()))
        }
    }
}
