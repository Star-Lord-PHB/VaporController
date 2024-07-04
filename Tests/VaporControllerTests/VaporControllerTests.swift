import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(VaporControllerMacros)
import VaporControllerMacros

let testMacros: [String: Macro.Type] = [
    "EndPoint": EndPointMacro.self,
    "Controller": ControllerMacro.self
]
#endif

final class VaporControllerTests: XCTestCase {
    
    func testMacro() throws {
        #if canImport(VaporControllerMacros)
        assertMacroExpansion(
            """
            @Controller
            struct Test {
                @EndPoint(path: "endpoints", "hello", ":name")
                func endPoint5(userName: String, @QueryParam(name: "pass") password: String) -> HTTPStatus {
                    return .ok
                }
            }
            """,
            expandedSource: "",
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacroWithStringLiteral() throws {
        #if canImport(VaporControllerMacros)
        assertMacroExpansion(
            #"""
            #stringify("Hello, \(name)")
            """#,
            expandedSource: #"""
            ("Hello, \(name)", #""Hello, \(name)""#)
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
