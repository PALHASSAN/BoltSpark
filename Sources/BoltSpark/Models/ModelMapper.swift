//
//  ModelMapper.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 25/09/1447 AH.
//

import Foundation

public class ModelMapper {
    nonisolated(unsafe) private static var relationKeysCache: [String: Set<String>] = [:]
    nonisolated(unsafe) private static var relationConfigCache: [String: [String: BoltRelation]] = [:]
    private static let lock = NSLock()

    public static func map<T: Model>(_ rows: [[String: Any]], to type: T.Type) throws -> [T] {
        if rows.isEmpty { return [] }

        let typeName = String(describing: T.self)
        
        lock.lock()
        let knownRelationKeys = relationKeysCache[typeName] ?? []
        
        var originalConfigs = relationConfigCache[typeName]
        if originalConfigs == nil {
            originalConfigs = [:]
            let dummy = T()
            let dummyMirror = Mirror(reflecting: dummy)
            
            for child in dummyMirror.children {
                if let label = child.label, let relation = child.value as? BoltRelation {
                    let cleanLabel = label.hasPrefix("_") ? String(label.dropFirst()) : label
                    originalConfigs?[cleanLabel] = relation
                }
            }
            relationConfigCache[typeName] = originalConfigs
        }
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
        var attemptedKeys: Set<String> = []
        
        while !success && retryCount < maxRetries {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: processedRows, options: [])
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                result = try decoder.decode([T].self, from: jsonData)
                success = true
                
            } catch let DecodingError.keyNotFound(key, _) {
                let missingKey = key.stringValue
                if attemptedKeys.contains(missingKey) {
                    throw BoltError.mappingError("Mapping failed: Key '\(missingKey)' is missing in \(typeName).")
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
                
            } catch {
                throw BoltError.mappingError("Unexpected Error: \(error.localizedDescription)")
            }
        }
   
        if let configs = originalConfigs, !configs.isEmpty {
            for model in result {
                let mirror = Mirror(reflecting: model)
                for child in mirror.children {
                    if let label = child.label, let decodedRelation = child.value as? BoltRelation {
                        let cleanLabel = label.hasPrefix("_") ? String(label.dropFirst()) : label
                        
                        if let originalConfig = configs[cleanLabel] {
                            decodedRelation.restoreConfig(from: originalConfig)
                        }
                    }
                }
            }
        }
        
        return result
    }
}
