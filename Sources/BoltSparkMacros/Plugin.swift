//
//  Plugin.swift
//  BoltSpark
//
//  Created by Alhassan AlMakki on 21/09/1447 AH.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct BoltSparkPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ModelMacro.self,
        RelationshipMacro.self
    ]
}
