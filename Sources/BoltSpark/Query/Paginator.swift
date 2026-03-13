//
//  Paginator.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 23/09/1447 AH.
//

import Foundation

public struct Paginator<T: Codable>: Codable {
    public let data: [T]
    public let total: Int               // Total from DB
    public let perPage: Int             // Total items per page
    public let currentPage: Int
    public let lastPage: Int
    
    public var hasMorePages: Bool {
        return currentPage < lastPage
    }
    
    public init(data: [T], total: Int, perPage: Int, currentPage: Int) {
        self.data = data
        self.total = total
        self.perPage = perPage
        self.currentPage = currentPage
        self.lastPage = max(1, Int(ceil(Double(total) / Double(perPage))))
    }
}
