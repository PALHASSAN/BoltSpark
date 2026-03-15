import Foundation

public final class BoltSpark: @unchecked Sendable {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var hasAutoIgnited = false
    
    nonisolated(unsafe) private static var drivers: [String: DatabaseDriver] = [:]
    static func driver(for name: String) throws -> DatabaseDriver {
        lock.lock()
        defer { lock.unlock() }
        
        if !hasAutoIgnited {
            autoIgnite()
        }
        
        guard let driver = drivers[name] ?? drivers["main"] else {
            throw BoltError.databaseNotFound(name)
        }
        return driver
    }
    
    private static func autoIgnite() {
        hasAutoIgnited = true
        let extensions = ["sqlite", "db", "sqlite3"]
        
        for ext in extensions {
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                for url in urls {
                    let dbName = url.deletingPathExtension().lastPathComponent
                    if let driver = try? SQLiteDriver(path: url.path) {
                        drivers[dbName] = driver
                        if drivers["main"] == nil {
                            drivers["main"] = driver
                        }
                    }
                }
            }
        }
    }
    
    public static func register(name: String = "main", driver: DatabaseDriver) {
        drivers[name] = driver
    }
    
    public static func isRegistered(_ name: String) -> Bool {
        return drivers[name] != nil
    }
    public static func unregister(_ name: String) {
        drivers.removeValue(forKey: name)
    }
}
