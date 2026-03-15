//
//  ModelMapper.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 25/09/1447 AH.
//

import Foundation

public class ModelMapper {
    nonisolated(unsafe) private static var relationsCache: [String: [String]] = [:]
    private static let lock = NSLock()

    public static func map<T: Model>(_ rows: [[String: Any]], to type: T.Type) throws -> [T] {
        if rows.isEmpty { return [] }

        let typeName = String(describing: T.self)
        lock.lock()
        
        if relationsCache[typeName] == nil {
            let template = unsafeBitCast(MemoryLayout<T>.size, to: T.self) //
            let mirror = Mirror(reflecting: template)
            relationsCache[typeName] = mirror.children.compactMap { child in
                if child.value is BoltRelation {
                    return child.label?.replacingOccurrences(of: "_", with: "")
                }
                return nil
            }
        }
        let relationKeys = relationsCache[typeName] ?? []
        lock.unlock()

        let processedRows = rows.map { row -> [String: Any] in
            var newRow = row
            for key in relationKeys {
                newRow[key] = NSNull()
            }
            return newRow
        }

        let jsonData = try JSONSerialization.data(withJSONObject: processedRows, options: [])
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            return try decoder.decode([T].self, from: jsonData)
        } catch {
            throw BoltError.mappingError("🧩 BoltSpark Mapping Failed: \(T.self) - \(error.localizedDescription)")
        }
    }
}
