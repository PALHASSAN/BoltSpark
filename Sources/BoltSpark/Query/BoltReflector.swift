//
//  BoltReflector.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 03/10/1447 AH.
//

import Foundation

public struct BoltReflector {
    public static func getRelation<T: Model>(from model: T.Type, named relationName: String) -> BoltRelation? {
        let dummyInstance = T()
        let mirror = Mirror(reflecting: dummyInstance)
        
        let child = mirror.children.first {
            $0.label?.replacingOccurrences(of: "_", with: "") == relationName
        }
        return child?.value as? BoltRelation
    }
}

fileprivate struct BoltMockDecoder: Decoder {
    var codingPath: [CodingKey] = []; var userInfo: [CodingUserInfoKey : Any] = [:]
    func container<K>(keyedBy type: K.Type) throws -> KeyedDecodingContainer<K> { KeyedDecodingContainer(KDC()) }
    func unkeyedContainer() throws -> UnkeyedDecodingContainer { UKC() }
    func singleValueContainer() throws -> SingleValueDecodingContainer { SVC() }
    
    struct KDC<Key: CodingKey>: KeyedDecodingContainerProtocol {
        var codingPath: [CodingKey] = []; var allKeys: [Key] = []
        func contains(_ key: Key) -> Bool { true }
        func decodeNil(forKey key: Key) throws -> Bool { true }
        func decode(_ t: Bool.Type, forKey k: Key) throws -> Bool { false }
        func decode(_ t: String.Type, forKey k: Key) throws -> String { "" }
        func decode(_ t: Double.Type, forKey k: Key) throws -> Double { 0 }
        func decode(_ t: Float.Type, forKey k: Key) throws -> Float { 0 }
        func decode(_ t: Int.Type, forKey k: Key) throws -> Int { 0 }
        func decode(_ t: Int64.Type, forKey k: Key) throws -> Int64 { 0 }
        func decode<T: Decodable>(_ t: T.Type, forKey k: Key) throws -> T { try T(from: BoltMockDecoder()) }
        func nestedContainer<N>(keyedBy t: N.Type, forKey k: Key) throws -> KeyedDecodingContainer<N> { KeyedDecodingContainer(KDC<N>()) }
        func nestedUnkeyedContainer(forKey k: Key) throws -> UnkeyedDecodingContainer { UKC() }
        func superDecoder() throws -> Decoder { BoltMockDecoder() }
        func superDecoder(forKey k: Key) throws -> Decoder { BoltMockDecoder() }
    }
    
    struct UKC: UnkeyedDecodingContainer {
        var codingPath: [CodingKey] = []; var count: Int? = 0; var isAtEnd: Bool = true; var currentIndex: Int = 0
        mutating func decodeNil() throws -> Bool { true }
        mutating func decode<T: Decodable>(_ t: T.Type) throws -> T { try T(from: BoltMockDecoder()) }
        mutating func nestedContainer<N>(keyedBy t: N.Type) throws -> KeyedDecodingContainer<N> { KeyedDecodingContainer(KDC<N>()) }
        mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer { self }
        mutating func superDecoder() throws -> Decoder { BoltMockDecoder() }
    }
    
    struct SVC: SingleValueDecodingContainer {
        var codingPath: [CodingKey] = []
        func decodeNil() -> Bool { true }
        func decode<T: Decodable>(_ t: T.Type) throws -> T { try T(from: BoltMockDecoder()) }
    }
}
