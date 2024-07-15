//
//  EndPointMacro.swift
//  
//
//  Created by Star_Lord_PHB on 2024/7/3.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation



public struct EndPointMacro: EndPointMacroProtocal {
    
    static let macroParameterParseRules: [ParameterListParsingRule] = [
        .labeled("method", canIgnore: true),
        .labeledVarArg("path", canIgnore: true),
        .labeledVarArg("middleware", canIgnore: true),
        .labeled("body", canIgnore: true),
    ]
    
    
    static func extractMacroParamters(
        parameters: [[LabeledExprSyntax]],
        declaration: FunctionDeclSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> MacroParam? {
        
        let method = parameters[0].first?.expression ?? ExprSyntax(MemberAccessExprSyntax(name: "GET"))
        
        let path = if !parameters[1].isEmpty {
            parameters[1].map { $0.expression }
        } else {
            [ExprSyntax(StringLiteralExprSyntax(content: declaration.name.trimmed.text))]
        }
        
        let middleware = parameters[2].map { $0.expression }
        
        let body = parameters[3].first?.expression ?? ExprSyntax(MemberAccessExprSyntax(name: "collect"))
        
        return .init(method: method, path: path, middleware: middleware, body: body)
        
    }
    
}
