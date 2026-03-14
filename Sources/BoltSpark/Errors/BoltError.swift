//
//  BoltError.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 21/09/1447 AH.
//

public enum BoltError: Error, LocalizedError {
    case connectionFailed(String)
    case invalidSQL(String)
    case executionError(String)
    case mappingError(String)
    case databaseNotFound(String)
    
    public var errorDescription: String? {
        switch self {
        case .connectionFailed(let msg): return "❌ BoltSpark Connection Error: \(msg)"
        case .invalidSQL(let msg): return "⚠️ BoltSpark SQL Syntax Error: \(msg)"
        case .executionError(let msg): return "🚫 BoltSpark Execution Failed: \(msg)"
        case .mappingError(let msg): return "🧩 BoltSpark Mapping Failed: \(msg)"
        case .databaseNotFound(let msg): return "📂 BoltSpark DB Not Found: \(msg)"
    }
}
