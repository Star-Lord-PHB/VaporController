//
//  CustomRouteBuilderMacro.swift
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


public struct CustomRouteBuilderMacro: MarkerMacro {
    
    struct CustomRouteBuilderSpec {
        let name: TokenSyntax
        let parameterLabel: TokenSyntax
        let useGlobalSetting: ExprSyntax
        let willThrows: Bool
        var confirmedUseGlobalSetting: Bool? {
            if let text = useGlobalSetting.as(BooleanLiteralExprSyntax.self)?.literal.trimmed.text {
                text == "true"
            } else {
                nil
            }
        }
    }
    
    
    static let macroParameterParseRules: [ParameterListParsingRule] = [
        .labeled("useControllerGlobalSetting", canIgnore: true)
    ]
    
    
    static func internalExpansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> CustomRouteBuilderSpec? {
        
        guard
            let declaration = declaration.as(FunctionDeclSyntax.self),
            !declaration.modifiers.contains(where: { $0.name.trimmed.text == "static" })
        else { return nil }
        let signature = declaration.signature
        
        let macroParameters: [[LabeledExprSyntax]]
        do {
            macroParameters = try node.arguments?
                .grouped(with: macroParameterParseRules) ?? .init(repeating: [], count: 1)
        } catch {
            context.diagnose(.init(node: node, message: error))
            return nil
        }
        
        let useGlobalSetting = macroParameters[0].first?.expression ?? ExprSyntax(false as BooleanLiteralExprSyntax)
        
        let parameterList = signature.parameterClause.parameters
        
        guard parameterList.count == 1, let parameter = parameterList.first else {
            let error = ParseError.parameterError(parameters: parameterList)
            context.diagnose(.init(node: parameterList, message: error, fixIts: error.fixit))
            return nil
        }
        
        if let asyncKeyword = signature.effectSpecifiers?.asyncSpecifier {
            let error = ParseError.unexpectedAsync(asyncKeyword: asyncKeyword)
            context.diagnose(.init(node: asyncKeyword, message: error, fixIts: error.fixit))
        }
        
        return .init(
            name: declaration.name.trimmed,
            parameterLabel: parameter.firstName.trimmed,
            useGlobalSetting: useGlobalSetting,
            willThrows: signature.effectSpecifiers?.throwsClause != nil
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



extension CustomRouteBuilderMacro {
    
    enum ParseError: LocalizedError, Identifiable, DiagnosticMessage {
        
        case attachTargetError
        case parameterError(parameters: FunctionParameterListSyntax)
        case unexpectedAsync(asyncKeyword: TokenSyntax)
        
        var id: String {
            switch self {
                case .attachTargetError: "AttachTargetError"
                case .parameterError: "ParameterError"
                case .unexpectedAsync: "UnexpectedAsync"
            }
        }
        
        var message: String {
            switch self {
                case .attachTargetError:
                    "CustomEndPoint macro can only be attached to member functions"
                case .parameterError:
                    "A custom route builder should receive one and only one parameter of type \"Vapor.RoutesBuilder\""
                case .unexpectedAsync:
                    "A custom route builder cannot be async since the boot(routes:) function of Vapor.RouteCollection is not async"
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
                            message: MacroExpansionFixItMessage("replace with (builder: RouteBuilder)"),
                            oldNode: parameters,
                            newNode: ["builder: RoutesBuilder"] as FunctionParameterListSyntax
                        )
                    ]
                case .unexpectedAsync(let asyncKeyword):
                    [
                        .replace(
                            message: MacroExpansionFixItMessage("remove async keyword"),
                            oldNode: asyncKeyword,
                            newNode: "" as TokenSyntax
                        )
                    ]
            }
        }
        
    }
    
}
