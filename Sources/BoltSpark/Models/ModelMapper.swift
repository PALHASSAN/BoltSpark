//
//  ModelMapper.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 25/09/1447 AH.
//

import Foundation

import Foundation

public class ModelMapper {
    nonisolated(unsafe) private static var relationsCache: [String: [String]] = [:]
    private static let lock = NSLock()

    public static func map<T: Model>(_ rows: [[String: Any]], to type: T.Type) throws -> [T] {
        if rows.isEmpty { return [] }

        let typeName = String(describing: T.self)
        
        lock.lock()
        if relationsCache[typeName] == nil {
            let size = MemoryLayout<T>.size
            let alignment = MemoryLayout<T>.alignment
            let pointer = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: alignment)
            pointer.initializeMemory(as: UInt8.self, repeating: 0, count: size)
            
            let dummy = pointer.assumingMemoryBound(to: T.self).pointee
            let mirror = Mirror(reflecting: dummy)
            
            relationsCache[typeName] = mirror.children.compactMap { child in
                if child.value is BoltRelation {
                    return child.label?.replacingOccurrences(of: "_", with: "")
                }
                return nil
            }
            pointer.deallocate()
        }
        let relationKeys = relationsCache[typeName] ?? []
        lock.unlock()
        
        let processedRows = rows.map { row -> [String: Any] in
            var newRow = row
            for key in relationKeys {
                if newRow[key] == nil {
                    newRow[key] = []
                }
            }
            return newRow
        }

        let jsonData = try JSONSerialization.data(withJSONObject: processedRows, options: [])
        let decoder = JSONDecoder()
    
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            return try decoder.decode([T].self, from: jsonData)
        } catch let DecodingError.keyNotFound(key, context) {
            let errorMsg = "❌ Missing Key: '\(key.stringValue)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            print(errorMsg)
            throw BoltError.mappingError(errorMsg)
        } catch let DecodingError.valueNotFound(value, context) {
            let errorMsg = "❌ Value Not Found (NULL where not allowed): \(value) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            print(errorMsg)
            throw BoltError.mappingError(errorMsg)
        } catch let DecodingError.typeMismatch(type, context) {
            let errorMsg = "❌ Type Mismatch: Expected \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            print(errorMsg)
            throw BoltError.mappingError(errorMsg)
        } catch {
            throw BoltError.mappingError("🧩 BoltSpark Mapping Failed: \(T.self) - \(error.localizedDescription)")
        }
    }
}
