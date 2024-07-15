//
//  EndPointMacroProtocal+Helpers.swift
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


struct EndPointSpec {
    
    let handlerFunctionDecl: [SwiftSyntax.DeclSyntax]
    let name: TokenSyntax
    let method: ExprSyntax
    let path: [ExprSyntax]
    let middleware: [ExprSyntax]
    let body: ExprSyntax
    
    func useHandlerStr(routeVarName: String) -> String {
        let pathComponentStrs = path.map({ $0.trimmedDescription })
        let middlewareStrs = middleware.map({ $0.trimmedDescription })
        let groupMiddlewareStr = middlewareStrs.isEmpty ? "" : ".grouped(\(middlewareStrs.joined(separator: ",")))\n\t"
        return "\(routeVarName)\(groupMiddlewareStr)"
            + ".on(\(method), \(pathComponentStrs.joined(separator: ",")), body: \(body), use: self.\(name)(req:))"
    }
    
}


struct MacroParam {
    let method: ExprSyntax
    let path: [ExprSyntax]
    let middleware: [ExprSyntax]
    let body: ExprSyntax
}


enum EndPointParameterType {
    
    case pathParam(name: ExprSyntax)
    case requestBody
    case queryParam(name: ExprSyntax)
    case queryContent
    case authContent
    case requestKeyPath(keyPath: ExprSyntax)
    case req(keyPath: ExprSyntax)
    
    private static let allCasesStr: Set<String> = [
        "PathParam", "RequestBody", "QueryParam", "QueryContent", "AuthContent", "RequestKeyPath", "Req"
    ]
    
    init(from parameter: FunctionParameterSyntax) throws(EndPointParseError) {
        
        let attributes = parameter.attributes.grouped()
        
        let count = attributes.keys.count(where: { Self.allCasesStr.contains($0) })
        guard count <= 1 else { throw .multipleRequestParameterTypeDeclaration }
        
        let attrs = attributes.first(where: { Self.allCasesStr.contains($0.key) })?.value
        guard attrs == nil || attrs?.count == 1 else {
            throw .multipleRequestParameterTypeDeclaration
        }
        
        let attr = attrs?.first
        var defaultName: ExprSyntax {
            .init(StringLiteralExprSyntax(content: (parameter.secondName ?? parameter.firstName).text))
        }
        var name: ExprSyntax { attr?.arguments?.grouped()["name"]?.first?.expression ?? defaultName }
        
        var defaultKeyPath: ExprSyntax {
            .init(KeyPathExprSyntax(components: [.init(period: ".", component: .init(.init(declName: .init(baseName: "self"))))]))
        }
        var keyPath: ExprSyntax { attr?.arguments?.grouped()[nil]?.first?.expression ?? defaultKeyPath }
        
        self = switch attr?.attributeName.trimmedDescription {
            case "PathParam": .pathParam(name: name)
            case "RequestBody": .requestBody
            case "QueryParam": .queryParam(name: name)
            case "QueryContent": .queryContent
            case "AuthContent": .authContent
            case "RequestKeyPath": .requestKeyPath(keyPath: keyPath)
            case "Req": .req(keyPath: keyPath)
            default: .pathParam(name: defaultName)
        }
        
    }
    
}


enum EndPointParseError: LocalizedError, Identifiable, DiagnosticMessage {
    
    case attachTargetError
    case multipleRequestParameterTypeDeclaration
    case unknown
    
    var id: String {
        switch self {
            case .multipleRequestParameterTypeDeclaration: "MultipleRequestParameterTypeDeclaration"
            case .attachTargetError: "AttachTargetError"
            case .unknown: "UnknownError"
        }
    }
    
    var message: String {
        switch self {
            case .multipleRequestParameterTypeDeclaration:
                "Parameter for request should have only one type"
            case .attachTargetError:
                "EndPoint macro can only be attached to member functions"
            case .unknown:
                "Unknown error occurs"
        }
    }
    
    var diagnosticID: SwiftDiagnostics.MessageID { .init(domain: "EndPointMacroError", id: id) }
    
    var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
    
    var errorDescription: String? { message }
    
}
