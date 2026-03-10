//
//  BoltError.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 21/09/1447 AH.
//

public enum BoltError: Error {
    case modelNotFound(String)
    case databaseError(String)
}
