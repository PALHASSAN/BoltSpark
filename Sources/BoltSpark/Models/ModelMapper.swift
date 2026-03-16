//
//  ModelMapper.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 25/09/1447 AH.
//

import Foundation

public class ModelMapper {
    // Cache to memorize discovered relations/missing keys for maximum performance
    nonisolated(unsafe) private static var relationKeysCache: [String: Set<String>] = [:]
    private static let lock = NSLock()

    public static func map<T: Model>(_ rows: [[String: Any]], to type: T.Type) throws -> [T] {
        if rows.isEmpty { return [] }

        let typeName = String(describing: T.self)
        
        // Fetch known missing keys (like relations) from cache
        lock.lock()
        let knownRelationKeys = relationKeysCache[typeName] ?? []
        lock.unlock()

        var processedRows = rows
        
        // Pre-inject known relations with empty arrays to prevent JSONDecoder crashes
        if !knownRelationKeys.isEmpty {
            processedRows = processedRows.map { row in
                var newRow = row
                for key in knownRelationKeys {
                    if newRow[key] == nil {
                        newRow[key] = [] // Satisfies MorphToMany and array relations
                    }
                }
                return newRow
            }
        }

        var success = false
        var result: [T] = []
        var retryCount = 0
        let maxRetries = 15 // Safe limit to prevent infinite loops
        
        // The Self-Healing Loop
        while !success && retryCount < maxRetries {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: processedRows, options: [])
                let decoder = JSONDecoder()
                
                // Automatically handle Snake Case (e.g., order_index -> orderIndex)
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                result = try decoder.decode([T].self, from: jsonData)
                success = true // Mapping succeeded!
                
            } catch let DecodingError.keyNotFound(key, context) {
                // Self-Healing: A relation or missing key was found.
                let missingKey = key.stringValue
                
                // Save to cache so we don't fail on this key ever again
                lock.lock()
                var keys = relationKeysCache[typeName] ?? []
                keys.insert(missingKey)
                relationKeysCache[typeName] = keys
                lock.unlock()
                
                // Inject an empty array for this specific key and retry
                processedRows = processedRows.map { row in
                    var newRow = row
                    newRow[missingKey] = []
                    return newRow
                }
                retryCount += 1
                
            } catch let DecodingError.valueNotFound(value, context) {
                let path = context.codingPath.map { $0.stringValue }.joined(separator: ".")
                throw BoltError.mappingError("❌ NULL value not allowed at column: '\(path)'. Expected type: \(value). Please make the property Optional in your Model or fix the database data.")
                
            } catch let DecodingError.typeMismatch(type, context) {
                let path = context.codingPath.map { $0.stringValue }.joined(separator: ".")
                throw BoltError.mappingError("❌ Type mismatch at column: '\(path)'. Expected type: \(type).")
                
            } catch {
                throw BoltError.mappingError("🧩 Unexpected Mapping Error for \(typeName): \(error.localizedDescription)")
            }
        }
        
        if !success {
            throw BoltError.mappingError("❌ Mapping failed for \(typeName) after reaching maximum healing retries.")
        }
        
        return result
    }
}
