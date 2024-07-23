// The Swift Programming Language
// https://docs.swift.org/swift-book

import Vapor


/// Denote an EndPoint (request handler)
/// - Parameter method: the HTTP method for this handler
/// - Parameter path: the path components of this handler
/// - Parameter middleware: the middleware used for this handler
/// - Parameter body: the body streaming strategy
///
/// This macro will scan through the parameters of the function attached to generate another
/// function that will correctly extract the required values from `Request` and call this handler
/// function using the extracted values
///
/// ```swift
/// @Controller
/// struct Controller {
///     @EndPoint(path: "hello", ":firstName", ":middleName", ":lastName")
///     func endPoint1(
///         firstName: String,
///         middleName: String = "",
///         lastName: String?
///     ) -> String {
///         return "Hello \(firstName) \(middleName) \(lastName ?? "")"
///     }
///     @EndPoint(method: .POST, path: "books", "add", middleware: User.authenticator(), body: .stream)
///     func endPoint2(
///         @RequestBody book: Book,
///         @AuthContent user: User
///     ) async throws -> HTTPStatus {
///         // some DB operations
///         return .ok
///     }
/// }
/// ```
///
/// The codes above will be expanded as follow:
///
/// ```swift
/// extension Controller: RouteCollection {
///     func boot(routes: RoutesBuilder) throws {
///         routes.on(
///             .GET, "hello", ":firstName", ":middleName", ":lastName",
///             body: .collect,
///             use: randPrefix_endPoint1_randSuffix(req:)
///         )
///         routes.grouped(User.authenticator()).on(
///             .POST, "books", "add",
///             body: .stream,
///             use: randPrefix_endPoint2_randSuffix(req:)
///         )
///     }
///     func randPrefix_endPoint1_randSuffix(req: Request) throws {
///         let firstName = try req.parameter.require("firstName", as: String.self)
///         let middleName = req.parameter.get("middleName", as: String.self) ?? ""
///         let lastName = req.parameter.get("lastName", as: String.self)
///         endPoint1(firstName: firstName, middleName: middleName, lastName: lastName)
///     }
///     func randPrefix_endPoint2_randSuffix(req: Request) async throws {
///         let book = try req.content.decode(Book.self)
///         let user = try req.auth.require(User.self)
///         try await endPoint2(book: book, user: user)
///     }
/// }
/// ```
///
/// - Attention: This macro MUST be attached to member functions of structs or classes that are
/// attached with ``Controller(path:middleware:)`` macro. And the actual expansion is done by
/// ``Controller(path:middleware:)``, thus expanding this macro will show nothing
@attached(peer)
public macro EndPoint(method: Vapor.HTTPMethod = .GET, path: String..., middleware: any Middleware..., body: HTTPBodyStreamStrategy = .collect) =
    #externalMacro(module: "VaporControllerMacros", type: "EndPointMacro")


/// Denote a Controller class / struct
/// - Parameter path: the global path components for all the handlers inside
/// - Parameter middleware: the global middleware used for all the handler inside
///
/// This macro will conform the attached class / struct to `RouteCollection` and automatically
/// implement the `boot(routes:)` method. The implementation is based on the handler functions
/// attached by ``EndPoint(method:path:middleware:)`` or ``CustomEndPoint(method:path:middleware:)``
/// or ``CustomRouteBuilder(useControllerGlobalSetting:)``
@attached(extension, conformances: RouteCollection, names: arbitrary)
public macro Controller(path: String..., middleware: any Middleware...) =
    #externalMacro(module: "VaporControllerMacros", type: "ControllerMacro")



//@attached(peer)
//public macro RequestBody() = #externalMacro(module: "VaporControllerMacros", type: "RequestBodyMacro")


/// Denote an EndPoint (request handler)
/// - Parameter method: the HTTP method for this handler
/// - Parameter path: the path components of this handler
/// - Parameter middleware: the middleware used for this handler
/// - Parameter body: the body streaming strategy
///
/// It is similar to ``EndPoint(method:path:middleware:)`` macro, but it requires that the
/// attached handler function to take one and only one parameter of type `Vapor.Request`
///
/// - Attention: This macro MUST be attached to member functions of structs or classes that are
/// attached with ``Controller(path:middleware:)`` macro.
///
/// - Seealso: ``EndPoint(method:path:middleware:)``
@attached(peer)
public macro CustomEndPoint(method: Vapor.HTTPMethod = .GET, path: String..., middleware: any Middleware..., body: HTTPBodyStreamStrategy = .collect) =
    #externalMacro(module: "VaporControllerMacros", type: "CustomEndPointMacro")


/// Denote an EndPoint (request handler)
/// - Parameter useControllerGlobalSetting: whether to use the global path and middleware declared
/// by the ``Controller(path:middleware:)`` macro, default is `false`
///
/// It is basically another `boot(routes:)` function that will be called by the original
/// `boot(routes:)` function. It requires that the attached function to take one and only one
/// parameter of type `Vapor.RoutesBuilder`
///
///
/// ```swift
/// @Controller(path: "base")
/// struct Controller {
///     @CustomRouteBuilder
///     func builder1(routes: RoutesBuilder) {
///         // do something
///     }
///     @CustomRouteBuilder(useControllerGlobalSetting: true)
///     func builder2(routes: RoutesBuilder) throws {
///         // do something
///     }
/// }
/// ```
///
/// The codes above will be expanded as follow:
///
/// ```swift
/// extension Controller: RouteCollection {
///     func boot(routes: RoutesBuilder) {
///         let routeWithGlobalSetting = routes.grouped("base")
///         builder1(routes: routes)
///         try builder2(routes: routeWithGlobalSetting)
///     }
/// }
/// ```
///
/// - Attention: This macro MUST be attached to member functions of structs or classes that are
/// attached with ``Controller(path:middleware:)`` macro, and the function CANNOT be async
@attached(peer)
public macro CustomRouteBuilder(useControllerGlobalSetting: Bool = false) =
    #externalMacro(module: "VaporControllerMacros", type: "CustomRouteBuilderMacro")
