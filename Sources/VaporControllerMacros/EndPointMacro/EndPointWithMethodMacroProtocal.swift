//
//  EndPointWithMethodMacroProtocal.swift
//  VaporController
//
//  Created by Star_Lord_PHB on 2024/7/14.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation


protocol EndPointWithMethodMacroProtocal: EndPointMacroProtocal {    
    static var method: ExprSyntax { get }
}


extension EndPointWithMethodMacroProtocal {
    
    static var macroParameterParseRules: [ParameterListParsingRule] {
        [
            .labeledVarArg("path", canIgnore: true),
            .labeledVarArg("middleware", canIgnore: true)
        ]
    }
    
    
    static func extractMacroParamters(
        parameters: [[LabeledExprSyntax]],
        declaration: FunctionDeclSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> MacroParam? {
        
        let path = if !parameters[0].isEmpty {
            parameters[0].map { $0.expression }
        } else {
            [ExprSyntax(StringLiteralExprSyntax(content: declaration.name.trimmed.text))]
        }
        
        let middleware = parameters[1].map { $0.expression }
        
        return .init(method: method, path: path, middleware: middleware)
        
    }
    
}
