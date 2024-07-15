//
//  GETMacro.swift
//  
//
//  Created by Star_Lord_PHB on 2024/7/11.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation


extension EndPointMacro {
    
    public struct GETMacro: EndPointWithMethodMacroProtocal {
        static let method: ExprSyntax = .init(MemberAccessExprSyntax(name: "GET"))
    }
    
    public struct POSTMacro: EndPointWithMethodMacroProtocal {
        static let method: ExprSyntax = .init(MemberAccessExprSyntax(name: "POST"))
    }
    
    public struct PUTMacro: EndPointWithMethodMacroProtocal {
        static let method: ExprSyntax = .init(MemberAccessExprSyntax(name: "PUT"))
    }
    
    public struct DELETEMacro: EndPointWithMethodMacroProtocal {
        static let method: ExprSyntax = .init(MemberAccessExprSyntax(name: "DELETE"))
    }
    
    public struct MOVEMacro: EndPointWithMethodMacroProtocal {
        static let method: ExprSyntax = .init(MemberAccessExprSyntax(name: "MOVE"))
    }
    
    public struct COPYMacro: EndPointWithMethodMacroProtocal {
        static let method: ExprSyntax = .init(MemberAccessExprSyntax(name: "COPY"))
    }
    
    public struct PATCHMacro: EndPointWithMethodMacroProtocal {
        static let method: ExprSyntax = .init(MemberAccessExprSyntax(name: "PATCH"))
    }
    
    public struct HEADMacro: EndPointWithMethodMacroProtocal {
        static let method: ExprSyntax = .init(MemberAccessExprSyntax(name: "HEAD"))
    }
    
    public struct OPTIONSMacro: EndPointWithMethodMacroProtocal {
        static let method: ExprSyntax = .init(MemberAccessExprSyntax(name: "OPTIONS"))
    }
    
}
