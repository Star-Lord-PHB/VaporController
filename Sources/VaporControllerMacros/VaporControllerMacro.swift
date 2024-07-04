import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


@main
struct VaporControllerPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        EndPointMacro.self,
        ControllerMacro.self,
//        RequestBodyMacro.self
    ]
}
