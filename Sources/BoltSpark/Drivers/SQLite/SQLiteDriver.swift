//
//  SQLiteDriver.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 25/09/1447 AH.
//

import Foundation
import SQLite3

public final class SQLiteDriver: DatabaseDriver, @unchecked Sendable {
    nonisolated(unsafe) private var db: OpaquePointer?
    private let lock = NSLock()
    
    public init(path: String) throws {
        lock.lock()
        defer { lock.unlock() }
        
        if sqlite3_open(path, &db) != SQLITE_OK {
            let error = String(cString: sqlite3_errmsg(db))
            throw BoltError.connectionFailed(error)
        }
#if DEBUG
        print("✅ BoltSpark: Connected to SQLite at \(path)")
#endif
    }
    
    public func execute(_ sql: String, arguments: [Any]) throws {
        lock.lock()
        defer { lock.unlock() }
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) != SQLITE_OK {
            throw BoltError.invalidSQL(String(cString: sqlite3_errmsg(db)))
        }
        
        try bind(arguments, to: statement)
        
        if sqlite3_step(statement) != SQLITE_DONE {
            throw BoltError.executionError(String(cString: sqlite3_errmsg(db)))
        }
        
        sqlite3_finalize(statement)
    }
    
    public func fetch(_ sql: String, arguments: [Any]) throws -> [[String: Any]] {
        lock.lock()
        defer { lock.unlock() }
        
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) != SQLITE_OK {
            throw BoltError.invalidSQL(String(cString: sqlite3_errmsg(db)))
        }
        
        try bind(arguments, to: statement)
        
        var results: [[String: Any]] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            results.append(parseRow(statement))
        }
        return results
    }
    
    private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    private func bind(_ args: [Any], to statement: OpaquePointer?) throws {
        for (index, arg) in args.enumerated() {
            let pos = Int32(index + 1)
            
            if let str = arg as? String {
                sqlite3_bind_text(statement, pos, str, -1, SQLITE_TRANSIENT)
            } else if let int = arg as? Int64 {
                sqlite3_bind_int64(statement, pos, int)
            } else if let int = arg as? Int {
                sqlite3_bind_int64(statement, pos, Int64(int))
            } else if let double = arg as? Double {
                sqlite3_bind_double(statement, pos, double)
            } else if let bool = arg as? Bool {
                sqlite3_bind_int64(statement, pos, bool ? 1 : 0)
            } else {
                sqlite3_bind_null(statement, pos)
            }
        }
    }
    
    private func parseRow(_ statement: OpaquePointer?) -> [String: Any] {
        var row: [String: Any] = [:]
        let colCount = sqlite3_column_count(statement)
        for i in 0..<colCount {
            let name = String(cString: sqlite3_column_name(statement, i))
            let type = sqlite3_column_type(statement, i)
            
            switch type {
            case SQLITE_INTEGER: row[name] = sqlite3_column_int64(statement, i)
            case SQLITE_TEXT: row[name] = String(cString: sqlite3_column_text(statement, i))
            case SQLITE_FLOAT: row[name] = sqlite3_column_double(statement, i)
            case SQLITE_NULL: row[name] = nil
            default: row[name] = String(cString: sqlite3_column_text(statement, i))
            }
        }
        return row
    }
    
    deinit {
        sqlite3_close(db)
    }
}
