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
    private static let lock = NSLock()
    
    nonisolated(unsafe) private static var _connections: [String: DatabaseWriter] = [:]
    nonisolated(unsafe) private static var _dataDirectory: String?

    public static var db: DatabaseWriter {
        return connection(for: "boltspark")
    }

    public static func connection(for name: String) -> DatabaseWriter {
        lock.lock()
        defer { lock.unlock() }
        
        let key = name.lowercased()
        
        if let existing = _connections[key] {
            return existing
        }
        
        if let dir = _dataDirectory,
           let path = Bundle.main.path(forResource: key, ofType: "sqlite", inDirectory: dir) {
            do {
                let queue = try DatabaseQueue(path: path)
                _connections[key] = queue
                setupValidation()
                return queue
            } catch {
                #if DEBUG
                print("⚠️ BoltSpark: Failed to open bundle database '\(key)': \(error)")
                #endif
            }
        }
        
        return initializeDefault(name: key)
    }

    public static func setup(directory: String) {
        lock.lock()
        self._dataDirectory = directory
        lock.unlock()
    }

    private static func initializeDefault(name: String) -> DatabaseWriter {
        do {
            let folderURL = try FileManager.default
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let dbURL = folderURL.appendingPathComponent("\(name).sqlite")
            
            let pool = try DatabasePool(path: dbURL.path)
            _connections[name] = pool
            setupValidation()
            return pool
        } catch {
            fatalError("⚡️ BoltSpark: Critical Error initializing '\(name)': \(error)")
        }
    }

    private static func setupValidation() {
        Task { @MainActor in
            ValidateConfig.setup(engine: .custom(BoltSparkVerifier()))
        }
    }
}
