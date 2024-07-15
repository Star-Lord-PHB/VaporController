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
        
        guard
            let macroParameterList = parseMacroParameterList(macro: node, in: context)
        else { return [] }
        
        let globalPath = macroParameterList[0].map { $0.expression }
        let globalMiddleware = macroParameterList[1].map { $0.expression }
        let hasGlobalSetting = !globalPath.isEmpty || !globalMiddleware.isEmpty
        
        let memberFunctions = declaration.memberBlock.members
            .compactMap { $0.decl.as(FunctionDeclSyntax.self) }
        
        let handlers = try expandAllEndPointHandlers(from: memberFunctions, in: context)
        let customHandlers = try expandAllCustomEndPoints(from: memberFunctions, in: context)
        let customRouteBuilders = try expandAllCustomRouteBuilders(from: memberFunctions, in: context)
        
        let originalRouteVarName = "routes"
        let routeWithGlobalSettingVarName = hasGlobalSetting ? "routeWithGlobalSetting" : "routes"
        
        let useHandlerStrs = handlers.map { handler in
            handler.useHandlerStr(routeVarName: routeWithGlobalSettingVarName)
        }
        
        let useCustomHandlerStrs = customHandlers.map { handler in
            handler.useHandlerStr(routeVarName: routeWithGlobalSettingVarName)
        }
        
        let useCustomRouteBuilderStrs = customRouteBuilders.map { builder in
            builder.useHandlerStr(
                routeWithGlobalSettingVarName: routeWithGlobalSettingVarName,
                routeWithoutGlobalSettingVarName: originalRouteVarName
            )
        }
        
        let globalPathStr = globalPath.isEmpty ? "" : ".grouped(\(globalPath.map({ $0.trimmedDescription }).joined(separator: ",")))"
        let globalMiddlewareStr = globalMiddleware.isEmpty ? "" : ".grouped(\(globalMiddleware.map({ $0.trimmedDescription }).joined(separator: ",")))"
        
        let globalGroupStr = hasGlobalSetting ? "let \(routeWithGlobalSettingVarName) = routes\(globalPathStr)\(globalMiddlewareStr)\n" : ""
        
        let extensionSyntax = try ExtensionDeclSyntax("extension \(type.trimmed): RouteCollection") {
            
            """
            func boot(routes: RoutesBuilder) throws {
                \(raw: globalGroupStr)\
                \(raw: useHandlerStrs.joined(separator: "\n"))
                \(raw: useCustomHandlerStrs.joined(separator: "\n"))
                \(raw: useCustomRouteBuilderStrs.joined(separator: "\n"))
            }
            """
            
            handlers.flatMap { $0.handlerFunctionDecl }
            
        }
        
        return [extensionSyntax]
        
    }
    
    
    private static func parseMacroParameterList(
        macro: AttributeSyntax,
        in context: MacroExpansionContext
    ) -> [[LabeledExprSyntax]]? {
        let macroParameterList: [[LabeledExprSyntax]]
        do {
            macroParameterList = try macro.arguments?
                .grouped(with: macroParameterParseRules) ?? .init(repeating: [], count: macroParameterParseRules.count)
        } catch {
            context.diagnose(.init(node: macro, message: error))
            return nil
        }
        return macroParameterList
    }
    
    
    private static func expandAllEndPointHandlers(
        from functions: [FunctionDeclSyntax],
        in context: some MacroExpansionContext
    ) throws -> [EndPointSpec] {
        
        try functions.flatMap { decl in
            
            try decl.attributes.compactMap { $0.as(AttributeSyntax.self) }.compactMap { attribute in
                
                switch attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.trimmed.text {
                    case "EndPoint": try EndPointMacro.internalExpansion(of: attribute, providingPeersOf: decl, in: context)
                    case "GET": try EndPointMacro.GETMacro.internalExpansion(of: attribute, providingPeersOf: decl, in: context)
                    case "POST": try EndPointMacro.POSTMacro.internalExpansion(of: attribute, providingPeersOf: decl, in: context)
                    case "PUT": try EndPointMacro.PUTMacro.internalExpansion(of: attribute, providingPeersOf: decl, in: context)
                    case "DELETE": try EndPointMacro.DELETEMacro.internalExpansion(of: attribute, providingPeersOf: decl, in: context)
                    case "HEAD": try EndPointMacro.HEADMacro.internalExpansion(of: attribute, providingPeersOf: decl, in: context)
                    case "PATCH": try EndPointMacro.PATCHMacro.internalExpansion(of: attribute, providingPeersOf: decl, in: context)
                    case "MOVE": try EndPointMacro.MOVEMacro.internalExpansion(of: attribute, providingPeersOf: decl, in: context)
                    case "COPY": try EndPointMacro.COPYMacro.internalExpansion(of: attribute, providingPeersOf: decl, in: context)
                    case "OPTIONS": try EndPointMacro.OPTIONSMacro.internalExpansion(of: attribute, providingPeersOf: decl, in: context)
                    default: nil
                }
                
            }
            
        }
        
    }
    
    
    private static func expandAllCustomEndPoints(
        from functions: [FunctionDeclSyntax],
        in context: some MacroExpansionContext
    ) throws -> [CustomEndPointMacro.CustomEndPointSpec] {
        try functions.flatMap { decl in
            try decl.attributes
                .filter(byName: "CustomEndPoint")
                .compactMap { try CustomEndPointMacro.internalExpansion(of: $0, providingPeersOf: decl, in: context) }
        }
    }
    
    
    private static func expandAllCustomRouteBuilders(
        from functions: [FunctionDeclSyntax],
        in context: some MacroExpansionContext
    ) throws -> [CustomRouteBuilderMacro.CustomRouteBuilderSpec] {
        try functions.flatMap { decl in
            try decl.attributes
                .filter(byName: "CustomRouteBuilder")
                .compactMap { try CustomRouteBuilderMacro.internalExpansion(of: $0, providingPeersOf: decl, in: context) }
        }
    }
    
}
