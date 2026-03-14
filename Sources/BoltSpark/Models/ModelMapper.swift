//
//  ModelMapper.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 25/09/1447 AH.
//

import Foundation

public class ModelMapper {
    public static func map<T: Decodable>(_ rows: [[String: Any]], to type: T.Type) throws -> [T] {
        let jsonData = try JSONSerialization.data(withJSONObject: rows, options: [])
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            return try decoder.decode([T].self, from: jsonData)
        } catch {
            throw BoltError.mappingError("Could not map database rows to \(T.self): \(error.localizedDescription)")
        }
    }
}
