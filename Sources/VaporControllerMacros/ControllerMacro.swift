//
//  ControllerMacro.swift
//  
//
//  Created by Star_Lord_PHB on 2024/7/2.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


public struct ControllerMacro: ExtensionMacro {
    
    static let macroParameterParseRules: [ParameterListParsingRule] = [
        .labeledVarArg("path", canIgnore: true),
        .labeledVarArg("middleware", canIgnore: true)
    ]
    
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        
        let macroParameterList: [[LabeledExprSyntax]]
        do {
            macroParameterList = try node.arguments?
                .grouped(with: macroParameterParseRules) ?? .init(repeating: [], count: macroParameterParseRules.count)
        } catch {
            context.diagnose(.init(node: node, message: error))
            return []
        }
        
        let extensionSyntax = try ExtensionDeclSyntax("extension \(type.trimmed): RouteCollection") {
            
            let memberFunctions = declaration.memberBlock.members
                .compactMap { $0.decl.as(FunctionDeclSyntax.self) }
                .compactMap { decl in
                    decl.attributes
                        .first(withName: "EndPoint")
                        .flatMap { (funcDecl: decl, attributeNode: $0) }
                }
            
            let globalPath = macroParameterList[0].map { $0.expression }
            let globalMiddleware = macroParameterList[1].map { $0.expression }
            
            let handlers = try memberFunctions.compactMap { (function, attributeNode) in
                try EndPointMacro.internalExpansion(of: attributeNode, providingPeersOf: function, in: context)
            }
            
            let handlerStrs = handlers.map { handler in
                let pathComponentStrs = handler.path.map({ $0.trimmedDescription })
                let middlewareStrs = handler.middleware.map({ $0.trimmedDescription })
                let groupMiddlewareStr = middlewareStrs.isEmpty ? "" : ".grouped(\(middlewareStrs.joined(separator: ",")))\n\t"
                return "routes\(groupMiddlewareStr)"
                + ".on(\(handler.method), \(pathComponentStrs.joined(separator: ",")), use: self.\(handler.name)(req:))"
            }
            
            let globalPathStr = globalPath.isEmpty ? "" : ".grouped(\(globalPath.map({ $0.trimmedDescription }).joined(separator: ",")))"
            let globalMiddlewareStr = globalMiddleware.isEmpty ? "" : ".grouped(\(globalMiddleware.map({ $0.trimmedDescription }).joined(separator: ",")))"
            
            let globalGroupStr = if globalPath.isEmpty && globalMiddleware.isEmpty {
                ""
            } else {
                "let routes = routes\(globalPathStr)\(globalMiddlewareStr)\n"
            }
            
            """
            func boot(routes: RoutesBuilder) throws {
                \(raw: globalGroupStr)\
                \(raw: handlerStrs.joined(separator: "\n"))
            }
            """
            
            handlers.flatMap { $0.handlerFunctionDecl }
            
        }
        
        return [extensionSyntax]
        
    }
    
}
