//
//  MarkerMacro.swift
//  
//
//  Created by Star_Lord_PHB on 2024/7/2.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


/// Macro that do nothing, simply serve as a marker for other macro
protocol MarkerMacro: PeerMacro {}


extension MarkerMacro {
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        []
    }
    
}
