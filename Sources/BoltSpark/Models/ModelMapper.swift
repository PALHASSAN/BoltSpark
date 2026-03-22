//
//  ModelMapper.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 25/09/1447 AH.
//

import Foundation

public class ModelMapper {
    nonisolated(unsafe) private static var relationKeysCache: [String: Set<String>] = [:]
    private static let lock = NSLock()

    public static func map<T: Model>(_ rows: [[String: Any]], to type: T.Type) throws -> [T] {
        if rows.isEmpty { return [] }

        let typeName = String(describing: T.self)
        lock.lock()
        let knownRelationKeys = relationKeysCache[typeName] ?? []
        lock.unlock()

        var processedRows = rows
        
        if !knownRelationKeys.isEmpty {
            processedRows = processedRows.map { row in
                var newRow = row
                for key in knownRelationKeys {
                    if newRow[key] == nil { newRow[key] = [] }
                }
                return newRow
            }
        }

        var success = false
        var result: [T] = []
        var retryCount = 0
        let maxRetries = 15
        var attemptedKeys: Set<String> = [] // Track keys to prevent infinite loops
        
        while !success && retryCount < maxRetries {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: processedRows, options: [])
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                result = try decoder.decode([T].self, from: jsonData)
                success = true
                
            } catch let DecodingError.keyNotFound(key, context) {
                let missingKey = key.stringValue
                
                // If we already tried this key and failed, break to avoid infinite loop
                if attemptedKeys.contains(missingKey) {
                    throw BoltError.mappingError("Mapping failed: Key '\(missingKey)' is missing or type mismatch in \(typeName). Check your CodingKeys or database schema.")
                }
                attemptedKeys.insert(missingKey)
                
                lock.lock()
                var keys = relationKeysCache[typeName] ?? []
                keys.insert(missingKey)
                relationKeysCache[typeName] = keys
                lock.unlock()
                
                processedRows = processedRows.map { row in
                    var newRow = row
                    newRow[missingKey] = []
                    return newRow
                }
                retryCount += 1
                
            } catch let DecodingError.valueNotFound(value, context) {
                let path = context.codingPath.map { $0.stringValue }.joined(separator: ".")
                throw BoltError.mappingError("NULL value found at column: '\(path)'. Expected type: \(value).")
            } catch let DecodingError.typeMismatch(type, context) {
                let path = context.codingPath.map { $0.stringValue }.joined(separator: ".")
                throw BoltError.mappingError("Type mismatch at column: '\(path)'. Expected type: \(type).")
            } catch {
                throw BoltError.mappingError("Unexpected Mapping Error for \(typeName): \(error.localizedDescription)")
            }
        }
        
        return result
    }
}
