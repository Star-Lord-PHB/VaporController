import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


@main
struct VaporControllerPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        EndPointMacro.self,
        ControllerMacro.self,
        CustomEndPointMacro.self,
        CustomRouteBuilderMacro.self
//        RequestBodyMacro.self
    ]
}
