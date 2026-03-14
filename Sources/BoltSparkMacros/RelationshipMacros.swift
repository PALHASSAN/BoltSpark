//
//  RelationshipMacros.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 22/09/1447 AH.
//

import SwiftSyntax
import SwiftSyntaxMacros

public struct RelationshipMacro: PeerMacro, AccessorMacro {
    
    static func parse(declaration: DeclSyntaxProtocol, node: AttributeSyntax) -> (identifier: String, modelType: String, macroName: String, extraArgs: String)? {
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
              let argList = node.arguments?.as(LabeledExprListSyntax.self),
              let firstArg = argList.first?.expression,
              let memberAccess = firstArg.as(MemberAccessExprSyntax.self),
              let base = memberAccess.base?.as(DeclReferenceExprSyntax.self),
              let macroName = node.attributeName.as(IdentifierTypeSyntax.self)?.name.text else {
            return nil
        }
        let extraArgsList = argList.dropFirst()
        let extraArgs = extraArgsList.isEmpty ? "" : ", " + extraArgsList.map { $0.description.trimmingCharacters(in: .whitespacesAndNewlines) }.joined(separator: ", ")
        
        return (identifier, base.baseName.text, macroName, extraArgs)
    }
    
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard let parsed = parse(declaration: declaration, node: node) else { return [] }
        let funcName = parsed.macroName.prefix(1).lowercased() + parsed.macroName.dropFirst()
        

        let generatedCode = "public static let `$\(parsed.identifier)` = \(funcName)(\(parsed.modelType).self\(parsed.extraArgs))"
        
        return [DeclSyntax(stringLiteral: generatedCode)]
    }

    public static func expansion(of node: AttributeSyntax, providingAccessorsOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax] {
        guard let parsed = parse(declaration: declaration, node: node) else { return [] }
        
        switch parsed.macroName {
        case "HasMany", "BelongsToMany", "MorphMany", "HasManyThrough":
            let generatedCode = """
            get throws {
                guard let id = self.id else { return [] } 
                let foreignKey = "\\(Self.tableName.singularized)_id"
                return try \(parsed.modelType).where(foreignKey, id).get()
            }
            """
            return [AccessorDeclSyntax(stringLiteral: generatedCode)]
            
        case "HasOne", "MorphOne", "HasOneThrough":
            let generatedCode = """
            get throws {
                guard let id = self.id else { return nil }
                let foreignKey = "\\(Self.tableName.singularized)_id"
                return try \(parsed.modelType).where(foreignKey, id).first()
            }
            """
            return [AccessorDeclSyntax(stringLiteral: generatedCode)]
            
        case "BelongsTo", "MorphTo":
            let generatedCode = """
                get throws {
                    guard let id = self.id else { return [] }
                    let laravelModelName = "App\\\\Models\\\\\(parsed.modelType)"
                    
                    return try \(parsed.modelType)
                        .whereHas("prayer_links") { query in
                            query.where("model_type", laravelModelName)
                                 .where("model_id", id)
                        }.get()
                }
                """
            return [AccessorDeclSyntax(stringLiteral: generatedCode)]
            
        default:
            return []
        }
    }
}
