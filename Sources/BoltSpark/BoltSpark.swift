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
        
        let standardExtensions = ["sqlite", "db", "sqlite3"]
        for ext in standardExtensions {
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                for url in urls {
                    registerDriverIfNeeded(for: url)
                }
            }
        }
        
        if let resourceURL = Bundle.main.resourceURL,
           let items = try? FileManager.default.contentsOfDirectory(
            at: resourceURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
           ) {
            for url in items where url.pathExtension.isEmpty {
                if isSQLiteFile(at: url) {
                    registerDriverIfNeeded(for: url)
                }
            }
        }
    }
    
    private static func registerDriverIfNeeded(for url: URL) {
        let dbName = url.deletingPathExtension().lastPathComponent
        if drivers[dbName] == nil, let driver = try? SQLiteDriver(path: url.path) {
            drivers[dbName] = driver
            if drivers["main"] == nil {
                drivers["main"] = driver
            }
        }
    }
    
    private static func isSQLiteFile(at url: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return false }
        defer { try? handle.close() }
        
        let header = handle.readData(ofLength: 16)
        let magicString = String(data: header, encoding: .utf8)
        return magicString?.hasPrefix("SQLite format 3") == true
    }
    
    public static func register(name: String = "main", driver: DatabaseDriver) {
        lock.lock()
        defer { lock.unlock() }
        drivers[name] = driver
    }
    
    public static func isRegistered(_ name: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return drivers[name] != nil
    }
    
    public static func unregister(_ name: String) {
        lock.lock()
        defer { lock.unlock() }
        drivers.removeValue(forKey: name)
    }
}
