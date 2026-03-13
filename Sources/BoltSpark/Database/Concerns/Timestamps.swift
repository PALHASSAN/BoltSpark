//
//  Timestamps.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 22/09/1447 AH.
//

import Foundation

public protocol Timestamps: Model {
    var created_at: Date? { get set }
    var updated_at: Date? { get set }
}
