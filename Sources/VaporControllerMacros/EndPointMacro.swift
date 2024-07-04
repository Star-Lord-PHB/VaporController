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



public struct EndPointMacro: MarkerMacro {
    
    struct EndPointSpec {
        let handlerFunctionDecl: [SwiftSyntax.DeclSyntax]
        let name: TokenSyntax
        let method: ExprSyntax
        let path: [ExprSyntax]
        let middleware: [ExprSyntax]
    }
    
    
    static let macroParameterParseRules: [ParameterListParsingRule] = [
        .labeled("method", canIgnore: true),
        .labeledVarArg("path", canIgnore: true),
        .labeledVarArg("middleware", canIgnore: true)
    ]
    
    
    static func internalExpansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> EndPointSpec? {
        
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
        
        let returnArrow = signature.returnClause?.arrow.trimmed ?? ""
        let returnType = signature.returnClause?.type.trimmed ?? ""
        let asyncKeyword = signature.effectSpecifiers?.asyncSpecifier?.trimmed ?? ""
        let awaitKeyword = (signature.effectSpecifiers?.asyncSpecifier != nil ? "await" : "") as TokenSyntax
        
        let method = macroParameters[0].first?.expression ?? ExprSyntax(MemberAccessExprSyntax(name: "GET"))
        
        let path = if !macroParameters[1].isEmpty {
            macroParameters[1].map { $0.expression }
        } else {
            [ExprSyntax(StringLiteralExprSyntax(content: declaration.name.trimmed.text))]
        }
        
        let middleware = macroParameters[2].map { $0.expression }
        
        let parameterList = signature.parameterClause.parameters
        
        let extractParametersOperations = parameterList.compactMap { parseExtractParametersOperation(from: $0, in: context) }
        guard extractParametersOperations.count == parameterList.count else {
            return nil
        }
        
        let passArgumentsOperations = parsePassParametersOperations(from: parameterList)
        
        let handlerName = context.makeUniqueName(declaration.name.text)
        
        let handlerDeclaration: [SwiftSyntax.DeclSyntax] = [
            """
            func \(handlerName)(req: Request) \(asyncKeyword) throws \(returnArrow) \(returnType) {
                \(raw: extractParametersOperations.joined(separator: "\n"))
                return \(awaitKeyword) \(declaration.name.trimmed)(\(raw: passArgumentsOperations.joined(separator: ",")))
            }
            """
        ]
        
        return .init(
            handlerFunctionDecl: handlerDeclaration,
            name: handlerName,
            method: method,
            path: path,
            middleware: middleware
        )
        
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
            context.diagnose(.init(node: declaration, message: ParseError.attachTargetError))
            return []
        }
        return []
    }
    
    
    private static func parseExtractParametersOperation(
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
                } else if parameter.type.as(OptionalTypeSyntax.self) != nil {
                    "let \(varName) = req.parameters.get(\(requestParamName), as: \(type).self)"
                } else {
                    "let \(varName) = try req.parameters.require(\(requestParamName), as: \(type).self)"
                }
            case .requestBody:
                "let \(varName) = try req.content.decode(\(type).self)"
            case .queryParam(let requestParamName):
                if let defaultValue = parameter.defaultValue {
                    "let \(varName) = req.query[\(type).self, at: \(requestParamName)] ?? \(defaultValue.value)"
                } else if parameter.type.as(OptionalTypeSyntax.self) != nil {
                    "let \(varName) = req.query[\(type).self, at: \(requestParamName)]"
                } else {
                    "let \(varName) = try req.query.get(\(type).self, at: \(requestParamName))"
                }
            case .queryContent:
                "let \(varName) = try req.query.decode(\(type).self)"
        }
        
    }
    
    
    private static func parsePassParametersOperations(from parameterList: FunctionParameterListSyntax) -> [String] {
        
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



extension EndPointMacro {
    
    enum EndPointParameterType {
        
        case pathParam(name: ExprSyntax)
        case requestBody
        case queryParam(name: ExprSyntax)
        case queryContent
        
        private static let allCasesStr: Set<String> = [
            "PathParam", "RequestBody", "QueryParam", "QueryContent"
        ]
        
        init(from parameter: FunctionParameterSyntax) throws(ParseError) {
            
            let attributes = parameter.attributes.grouped()
            
            let count = attributes.keys.count(where: { Self.allCasesStr.contains($0) })
            guard count <= 1 else { throw .multipleRequestParameterTypeDeclaration }
            
            let attrs = attributes.first(where: { Self.allCasesStr.contains($0.key) })?.value
            guard attrs == nil || attrs?.count == 1 else {
                throw .multipleRequestParameterTypeDeclaration
            }
            
            let attr = attrs?.first
            var defaultName: ExprSyntax {
                ExprSyntax(StringLiteralExprSyntax(content: (parameter.secondName ?? parameter.firstName).text))
            }
            var name: ExprSyntax { attr?.arguments?.grouped()["name"]?.first?.expression ?? defaultName }
            
            self = switch attr?.attributeName.trimmedDescription {
                case "PathParam": .pathParam(name: name)
                case "RequestBody": .requestBody
                case "QueryParam": .queryParam(name: name)
                case "QueryContent": .queryContent
                default: .pathParam(name: defaultName)
            }
            
        }
        
    }
    
}



extension EndPointMacro {
    
    enum ParseError: LocalizedError, Identifiable, DiagnosticMessage {
        
        case attachTargetError
        case multipleRequestParameterTypeDeclaration
        
        var id: String {
            switch self {
                case .multipleRequestParameterTypeDeclaration: "MultipleRequestParameterTypeDeclaration"
                case .attachTargetError: "AttachTargetError"
            }
        }
        
        var message: String {
            switch self {
                case .multipleRequestParameterTypeDeclaration:
                    "Parameter for request should have only one type"
                case .attachTargetError:
                    "EndPoint macro can only be attached to member functions"
            }
        }
        
        var diagnosticID: SwiftDiagnostics.MessageID { .init(domain: "EndPointMacroError", id: id) }
        
        var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
        
        var errorDescription: String? { message }
        
    }
    
}
