//
//  ModelMapper.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 25/09/1447 AH.
//

import Foundation

public class ModelMapper {
    public static func map<T: Model>(_ rows: [[String: Any]], to type: T.Type) throws -> [T] {
        if rows.isEmpty { return [] }

        let jsonData = try JSONSerialization.data(withJSONObject: rows, options: [])
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            return try decoder.decode([T].self, from: jsonData)
        } catch {
            #if DEBUG
            print("❌ BoltSpark Mapping Error in \(T.self): \(error)")
            #endif
            throw BoltError.mappingError("Could not map database rows to \(T.self): \(error.localizedDescription)")
        }
    }
}
