//
//  ModelMacro.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 21/09/1447 AH.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import Foundation

public enum ModelMacroError: Error, CustomStringConvertible {
    case onlyApplicableToStruct
    
    public var description: String {
        switch self {
        case .onlyApplicableToStruct:
            return "⚡️ BoltSpark: @Model can only be applied to a struct."
        }
    }
}

public struct ModelMacro: MemberMacro, ExtensionMacro {
    
    // MARK: - Extension Macro (Adding Protocol)
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        
        guard declaration.is(StructDeclSyntax.self) else {
            throw ModelMacroError.onlyApplicableToStruct
        }
        
        let modelExtension = try ExtensionDeclSyntax("extension \(type.trimmed): Model {}")
        return [modelExtension]
    }

    // MARK: - Member Macro (Generating Methods)
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw ModelMacroError.onlyApplicableToStruct
        }

        var storedProperties: [(name: String, type: String)] = []
        
        for member in structDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }
            
            for binding in varDecl.bindings {
                if binding.accessorBlock != nil { continue }
                
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                      let typeAnnotation = binding.typeAnnotation else { continue }
                
                let name = pattern.identifier.text
                let type = typeAnnotation.type.trimmedDescription
                
                if name != "id" {
                    storedProperties.append((name, type))
                }
            }
        }

        let params = storedProperties.map { "\($0.name): \($0.type)" }.joined(separator: ", ")
        let initArgs = storedProperties.map { "\($0.name): \($0.name)" }.joined(separator: ", ")
        let assignments = storedProperties.map { "self.\($0.name) = \($0.name)" }.joined(separator: "\n        ")
        return [
            """
            @discardableResult
            public static func create(\(raw: params)) throws -> Self {
                var record = Self(\(raw: initArgs))
                return try record.create()
            }
            """,
            """
            @discardableResult
            public static func update(id: Int64, \(raw: params)) throws -> Self {
                var record = Self(\(raw: initArgs))
                record.id = id
                return try record.update()
            }
            """,
            """
            public init(\(raw: params)) {
                self.id = nil
                \(raw: assignments)
            }
            """
        ]
    }
}
