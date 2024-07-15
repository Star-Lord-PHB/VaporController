//
//  CustomEndPointMacro.swift
//  
//
//  Created by Star_Lord_PHB on 2024/7/4.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation



public struct CustomEndPointMacro: MarkerMacro {
    
    struct CustomEndPointSpec {
        
        let name: TokenSyntax
        let method: ExprSyntax
        let path: [ExprSyntax]
        let middleware: [ExprSyntax]
        let body: ExprSyntax
        let parameterLabel: TokenSyntax
        
        func useHandlerStr(routeVarName: String) -> String {
            let pathComponentStrs = path.map({ $0.trimmedDescription })
            let middlewareStrs = middleware.map({ $0.trimmedDescription })
            let groupMiddlewareStr = middlewareStrs.isEmpty ? "" : ".grouped(\(middlewareStrs.joined(separator: ",")))\n\t"
            let label = parameterLabel
            return "\(routeVarName)\(groupMiddlewareStr)"
            + ".on(\(method), \(pathComponentStrs.joined(separator: ",")), body: \(body), use: self.\(name)(\(label):))"
        }
        
    }
    
    
    static let macroParameterParseRules: [ParameterListParsingRule] = [
        .labeled("method", canIgnore: true),
        .labeledVarArg("path", canIgnore: true),
        .labeledVarArg("middleware", canIgnore: true),
        .labeled("body", canIgnore: true)
    ]
    
    
    static func internalExpansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> CustomEndPointSpec? {
        
        guard
            let declaration = declaration.as(FunctionDeclSyntax.self),
            !declaration.modifiers.contains(where: { $0.name.trimmed.text == "static" })
        else { return nil }
        let signature = declaration.signature
        
        let macroParameters: [[LabeledExprSyntax]]
        do {
            macroParameters = try node.arguments?
                .grouped(with: macroParameterParseRules) ?? .init(repeating: [], count: macroParameterParseRules.count)
        } catch {
            context.diagnose(.init(node: node, message: error))
            return nil
        }
        
        let method = macroParameters[0].first?.expression ?? ExprSyntax(MemberAccessExprSyntax(name: "GET"))
        
        let path = if !macroParameters[1].isEmpty {
            macroParameters[1].map { $0.expression }
        } else {
            [ExprSyntax(StringLiteralExprSyntax(content: declaration.name.trimmed.text))]
        }
        
        let middleware = macroParameters[2].map { $0.expression }
        
        let body = macroParameters[3].first?.expression ?? ExprSyntax(MemberAccessExprSyntax(name: "collect"))
        
        let parameterList = signature.parameterClause.parameters
        
        guard parameterList.count == 1, let parameter = parameterList.first else {
            let error = ParseError.parameterError(parameters: parameterList)
            context.diagnose(.init(node: parameterList, message: error, fixIts: error.fixit))
            return nil
        }
        
        return .init(
            name: declaration.name.trimmed,
            method: method,
            path: path,
            middleware: middleware,
            body: body,
            parameterLabel: parameter.firstName.trimmed
        )
        
    }
    
    
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        guard
            let declaration = declaration.as(FunctionDeclSyntax.self),
            !declaration.modifiers.contains(where: { $0.name.trimmed.text == "static" })
        else {
            context.diagnose(.init(node: declaration, message: ParseError.attachTargetError))
            return []
        }
        return []
        
    }
    
}



extension CustomEndPointMacro {
    
    enum ParseError: LocalizedError, Identifiable, DiagnosticMessage {
        
        case attachTargetError
        case parameterError(parameters: FunctionParameterListSyntax)
        
        var id: String {
            switch self {
                case .attachTargetError: "AttachTargetError"
                case .parameterError: "ParameterError"
            }
        }
        
        var message: String {
            switch self {
                case .attachTargetError:
                    "CustomEndPoint macro can only be attached to member functions"
                case .parameterError:
                    "A custom endpoint handler function should receive one and only one parameter of type \"Vapor.Request\""
            }
        }
        
        var diagnosticID: SwiftDiagnostics.MessageID { .init(domain: "CustomEndPointMacroError", id: id) }
        
        var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
        
        var errorDescription: String? { message }
        
        var fixit: [FixIt] {
            switch self {
                case .attachTargetError: []
                case .parameterError(let parameters):
                    [
                        .replace(
                            message: MacroExpansionFixItMessage("replace with (req: Request)"),
                            oldNode: parameters,
                            newNode: FunctionParameterListSyntax(itemsBuilder: { "req: Request" })
                        )
                    ]
            }
        }
        
    }
    
}
