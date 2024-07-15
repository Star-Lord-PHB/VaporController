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
        CustomRouteBuilderMacro.self,
        EndPointMacro.GETMacro.self,
        EndPointMacro.POSTMacro.self,
        EndPointMacro.PUTMacro.self,
        EndPointMacro.DELETEMacro.self,
        EndPointMacro.MOVEMacro.self,
        EndPointMacro.COPYMacro.self,
        EndPointMacro.PATCHMacro.self,
        EndPointMacro.HEADMacro.self,
        EndPointMacro.OPTIONSMacro.self,
//        RequestBodyMacro.self
    ]
}
