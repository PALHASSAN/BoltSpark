import Foundation

public final class BoltSpark: @unchecked Sendable {
    private static let lock = NSLock()
    
    nonisolated(unsafe) private static var drivers: [String: DatabaseDriver] = [:]
    static func driver(for name: String) throws -> DatabaseDriver {
        lock.lock()
        defer { lock.unlock() }
        
        guard let driver = drivers[name] else {
            throw BoltError.databaseNotFound(name)
        }
        return driver
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
