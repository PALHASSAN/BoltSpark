import Foundation
import GRDB

@attached(member, names: named(create), named(update), named(init))
@attached(extension, conformances: Model)
public macro Model() = #externalMacro(module: "BoltSparkMacros", type: "ModelMacro")

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
    }
}
