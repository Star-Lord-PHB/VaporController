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
        
        typealias MemberFunctionSpec = (funcDecl: FunctionDeclSyntax, attributeNode: AttributeSyntax)
        
        let macroParameterList: [[LabeledExprSyntax]]
        do {
            macroParameterList = try node.arguments?
                .grouped(with: macroParameterParseRules) ?? .init(repeating: [], count: macroParameterParseRules.count)
        } catch {
            context.diagnose(.init(node: node, message: error))
            return []
        }
        
        let memberFunctions = declaration.memberBlock.members
            .compactMap { $0.decl.as(FunctionDeclSyntax.self) }
            .reduce(into: [String:[MemberFunctionSpec]]()) { group, decl in
                decl.attributes.first(withName: "EndPoint")
                    .map { group["EndPoint", default: []].append((decl, $0)) }
                decl.attributes.first(withName: "CustomEndPoint")
                    .map { group["CustomEndPoint", default: []].append((decl, $0)) }
                decl.attributes.first(withName: "CustomRouteBuilder")
                    .map { group["CustomRouteBuilder", default: []].append((decl, $0)) }
            }
        
        let globalPath = macroParameterList[0].map { $0.expression }
        let globalMiddleware = macroParameterList[1].map { $0.expression }
        let hasGlobalSetting = !globalPath.isEmpty || !globalMiddleware.isEmpty
        
        let handlers = try memberFunctions["EndPoint", default: []].compactMap { function, attributeNode in
            try EndPointMacro.internalExpansion(of: attributeNode, providingPeersOf: function, in: context)
        }
        
        let customHandlers = try memberFunctions["CustomEndPoint", default: []].compactMap { function, attributeNode in
            try CustomEndPointMacro.internalExpansion(of: attributeNode, providingPeersOf: function, in: context)
        }
        
        let customRouteBuilders = try memberFunctions["CustomRouteBuilder", default: []].compactMap { function, attributeNode in
            try CustomRouteBuilderMacro.internalExpansion(of: attributeNode, providingPeersOf: function, in: context)
        }
        
        let originalRouteVarName = "routes"
        let routeWithGlobalSettingVarName = hasGlobalSetting ? "routeWithGlobalSetting" : "routes"
        
        let useHandlerStrs = handlers.map { handler in
            let pathComponentStrs = handler.path.map({ $0.trimmedDescription })
            let middlewareStrs = handler.middleware.map({ $0.trimmedDescription })
            let groupMiddlewareStr = middlewareStrs.isEmpty ? "" : ".grouped(\(middlewareStrs.joined(separator: ",")))\n\t"
            return "\(routeWithGlobalSettingVarName)\(groupMiddlewareStr)"
            + ".on(\(handler.method), \(pathComponentStrs.joined(separator: ",")), use: self.\(handler.name)(req:))"
        }
        
        let useCustomHandlerStrs = customHandlers.map { handler in
            let pathComponentStrs = handler.path.map({ $0.trimmedDescription })
            let middlewareStrs = handler.middleware.map({ $0.trimmedDescription })
            let groupMiddlewareStr = middlewareStrs.isEmpty ? "" : ".grouped(\(middlewareStrs.joined(separator: ",")))\n\t"
            let label = handler.parameterLabel
            return "\(routeWithGlobalSettingVarName)\(groupMiddlewareStr)"
            + ".on(\(handler.method), \(pathComponentStrs.joined(separator: ",")), use: self.\(handler.name)(\(label):))"
        }
        
        let useCustomRouteBuilderStrs = customRouteBuilders.map { builder in
            let label = builder.parameterLabel.text == "_" ? "" : "\(builder.parameterLabel): "
            let tryKeyword = builder.willThrows ? "try " : ""
            return if let confirmedUseGlobalSetting = builder.confirmedUseGlobalSetting {
                "\(tryKeyword)self.\(builder.name)(\(label)\(confirmedUseGlobalSetting ? routeWithGlobalSettingVarName : originalRouteVarName))"
            } else {
                "\(tryKeyword)self.\(builder.name)(\(label)\(builder.useGlobalSetting))"
            }
            
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
    
}
