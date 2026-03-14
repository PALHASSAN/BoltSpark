//
//  DatabaseDriver.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 25/09/1447 AH.
//

import Foundation

public protocol DatabaseDriver {
    func execute(_ sql: String, arguments: [Any]) throws
    func fetch(_ sql: String, arguments: [Any]) throws -> [[String: Any]]
}
