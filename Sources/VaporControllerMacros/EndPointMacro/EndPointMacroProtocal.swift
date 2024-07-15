//
//  EndPointMacroProtocal.swift
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


protocol EndPointMacroProtocal: MarkerMacro {
    
    static var macroParameterParseRules: [ParameterListParsingRule] { get }
    
    static func extractMacroParamters(
        parameters: [[LabeledExprSyntax]],
        declaration: FunctionDeclSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> MacroParam?
    
    static func generateHandlerDeclaration(
        from declaration: FunctionDeclSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> (name: TokenSyntax, decl: [SwiftSyntax.DeclSyntax])?
    
}



extension EndPointMacroProtocal {
    
    static func internalExpansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> EndPointSpec? {
        
        guard
            let declaration = declaration.as(FunctionDeclSyntax.self),
            let macroParameters = parseMacroParams(from: node, with: macroParameterParseRules, in: context)
        else { return nil }
        
        guard let param = try extractMacroParamters(
            parameters: macroParameters,
            declaration: declaration,
            in: context
        ) else {
            return nil
        }
        
        guard
            let (handlerName, handlerDeclaration) = try generateHandlerDeclaration(from: declaration, in: context)
        else {
            context.diagnose(.init(node: node, message: EndPointParseError.unknown))
            return nil
        }
        
        return .init(
            handlerFunctionDecl: handlerDeclaration,
            name: handlerName,
            method: param.method,
            path: param.path,
            middleware: param.middleware,
            body: param.body
        )
        
    }
    
    
    static func generateHandlerDeclaration(
        from declaration: FunctionDeclSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> (name: TokenSyntax, decl: [SwiftSyntax.DeclSyntax])? {
        
        let signature = declaration.signature
        let name = declaration.name
        
        let returnArrow = signature.returnClause?.arrow.trimmed ?? ""
        let returnType = signature.returnClause?.type.trimmed ?? ""
        let asyncKeyword = signature.effectSpecifiers?.asyncSpecifier?.trimmed ?? ""
        let awaitKeyword = (signature.effectSpecifiers?.asyncSpecifier != nil ? "await " : "") as TokenSyntax
        let tryKeyword = (signature.effectSpecifiers?.throwsClause != nil ? "try " : "") as TokenSyntax
        
        let parameterList = signature.parameterClause.parameters
        let passArgumentsOperations = parsePassParametersOperations(from: parameterList)
        
        let extractParametersOperations = parameterList.compactMap { parseExtractParametersOperation(from: $0, in: context) }
        guard extractParametersOperations.count == parameterList.count else {
            return nil
        }
        
        let handlerName = context.makeUniqueName(name.trimmed.text)
        
        let decl: [SwiftSyntax.DeclSyntax] = [
            """
            @Sendable
            func \(handlerName)(req: Request) \(asyncKeyword) throws \(returnArrow) \(returnType) {
                \(raw: extractParametersOperations.joined(separator: "\n"))
                return \(tryKeyword)\(awaitKeyword)\(declaration.name.trimmed)(\(raw: passArgumentsOperations.joined(separator: ",")))
            }
            """
        ]
        
        return (handlerName, decl)
        
    }
    
    
    static func parseMacroParams(
        from node: AttributeSyntax,
        with rules: [ParameterListParsingRule],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) -> [[LabeledExprSyntax]]? {
        
        do {
            return try node.arguments?.grouped(with: rules)
            ?? .init(repeating: [], count: rules.count)
        } catch {
            context.diagnose(.init(node: node, message: error))
            return nil
        }
        
    }
    
    
    /// perform the basic validation
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard
            let declaration = declaration.as(FunctionDeclSyntax.self),
            !declaration.modifiers.contains(where: { $0.name.trimmed.text == "static" })
        else {
            context.diagnose(.init(node: declaration, message: EndPointParseError.attachTargetError))
            return []
        }
        return []
    }
    
    
    static func parseExtractParametersOperation(
        from parameter: FunctionParameterSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) -> String? {
        
        let parameterType: EndPointParameterType
        do {
            parameterType = try EndPointParameterType(from: parameter)
        } catch {
            context.diagnose(.init(node: parameter, message: error))
            return nil
        }
        
        let varName = (parameter.secondName ?? parameter.firstName).trimmed
        let type = parameter.type.as(OptionalTypeSyntax.self)?.wrappedType.trimmed ?? parameter.type.trimmed
        
        return switch parameterType {
            case .pathParam(let requestParamName):
                if let defaultValue = parameter.defaultValue {
                    "let \(varName) = req.parameters.get(\(requestParamName), as: \(type).self) ?? \(defaultValue.value)"
                } else if parameter.type.is(OptionalTypeSyntax.self) {
                    "let \(varName) = req.parameters.get(\(requestParamName), as: \(type).self)"
                } else {
                    "let \(varName) = try req.parameters.require(\(requestParamName), as: \(type).self)"
                }
            case .requestBody:
                if let defaultValue = parameter.defaultValue {
                    "let \(varName) = (try? req.content.decode(\(type.self))) ?? \(defaultValue)"
                } else if parameter.type.is(OptionalTypeSyntax.self) {
                    "let \(varName) = try? req.content.decode(\(type.self))"
                } else {
                    "let \(varName) = try req.content.decode(\(type).self)"
                }
            case .queryParam(let requestParamName):
                if let defaultValue = parameter.defaultValue {
                    "let \(varName) = req.query[\(type).self, at: \(requestParamName)] ?? \(defaultValue.value)"
                } else if parameter.type.is(OptionalTypeSyntax.self) {
                    "let \(varName) = req.query[\(type).self, at: \(requestParamName)]"
                } else {
                    "let \(varName) = try req.query.get(\(type).self, at: \(requestParamName))"
                }
            case .queryContent:
                if let defaultValue = parameter.defaultValue {
                    "let \(varName) = (try? req.query.decode(\(type).self)) ?? \(defaultValue)"
                } else if parameter.type.is(OptionalTypeSyntax.self) {
                    "let \(varName) = try? req.query.decode(\(type).self)"
                } else {
                    "let \(varName) = try req.query.decode(\(type).self)"
                }
            case .authContent:
                if let defaultValue = parameter.defaultValue {
                    "let \(varName) = req.auth.get(\(type).self) ?? \(defaultValue.value)"
                } else if parameter.type.is(OptionalTypeSyntax.self) {
                    "let \(varName) = req.auth.get(\(type).self)"
                } else {
                    "let \(varName) = try req.auth.require(\(type).self)"
                }
            case .requestKeyPath(let keyPath), .req(let keyPath):
                "let \(varName) = req[keyPath: \(keyPath)]"
        }
        
    }
    
    
    static func parsePassParametersOperations(from parameterList: FunctionParameterListSyntax) -> [String] {
        
        parameterList.map { parameter in
            return if let argName = parameter.secondName?.trimmed, parameter.firstName.trimmed.text != "_" {
                "\(parameter.firstName.trimmed): \(argName)"
            } else if let argName = parameter.secondName?.trimmed {
                "\(argName)"
            } else {
                "\(parameter.firstName.trimmed): \(parameter.firstName.trimmed)"
            }
        }
        
    }
    
}
