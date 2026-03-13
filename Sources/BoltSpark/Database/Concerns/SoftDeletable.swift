//
//  SoftDeletable.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 22/09/1447 AH.
//

import Foundation
import GRDB

public protocol SoftDeletable: Model {
    var deleted_at: Date? { get set }
}
