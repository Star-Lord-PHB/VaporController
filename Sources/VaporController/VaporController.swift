// The Swift Programming Language
// https://docs.swift.org/swift-book

import VaporControllerMacros
import Vapor


/// Denote an EndPoint (request handler)
/// - Parameter method: the HTTP method for this handler
/// - Parameter path: the path components of this handler
/// - Parameter middleware: the middleware used for this handler
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
///     @EndPoint(method: .POST, path: "books", "add", middleware: User.authenticator())
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
///             use: randPrefix_endPoint1_randSuffix(req:)
///         )
///         routes.grouped(User.authenticator()).on(
///             .POST, "books", "add",
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
public macro EndPoint(method: Vapor.HTTPMethod = .GET, path: String..., middleware: any Middleware...) =
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
///
/// It is similar to ``EndPoint(method:path:middleware:)`` macro, but it requires that the
/// attached handler function to take one and only one parameter of type `Vapor.Request`
///
/// - Attention: This macro MUST be attached to member functions of structs or classes that are
/// attached with ``Controller(path:middleware:)`` macro.
///
/// - Seealso: ``EndPoint(method:path:middleware:)``
@attached(peer)
public macro CustomEndPoint(method: Vapor.HTTPMethod = .GET, path: String..., middleware: any Middleware...) =
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


/// A property wrapper denoting a parameter of a request handler function to have its value
/// retrived from the `content` property of the request
///
/// ```swift
/// @EndPoint(method: .POST)
/// func endPoint1(@RequestBody book: Book) throws -> HTTPStatus { ... }
/// @EndPoint(method: .POST)
/// func endPoint2(@RequestBody book: Book?) throws -> HTTPStatus { ... }
/// @EndPoint(method: .POST)
/// func endPoint3(@RequestBody book: Book = .default) throws -> HTTPStatus { ... }
/// ```
///
/// The request handler signature above will leads to the following codes:
///
/// ```swift
/// // endPoint1
/// let book = try req.content.decode(Book.self)
/// // endPoint2
/// let book = try? req.content.decode(Book.self)
/// // endPoint3
/// let book = (try? req.content.decode(Book.self)) ?? .default
/// ```
///
/// - Note: This property wrapper only works as a marker for macro expansion, it itself does
/// nothing
@propertyWrapper
public struct RequestBody<T: Content>: Content {
    public var wrappedValue: T
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
}


/// A property wrapper denoting a paramter of a request handler function to have its value
/// retrived from the `parameter` property of the request
///
/// - Parameter name: specify the key for extracting the parameter from request, if the key
/// is not the same as the parameter name
///
/// This is the default behaviour of a parameter, so if no property wrapper is attached to
/// a parameter, it will be a `PathParam`
///
/// ```swift
/// @EndPoint
/// func endPoint1(
///     firstName: String,
///     @PathParam middleName: String?
///     @PathParam(name: "last_name") lastName: String = ""
/// ) -> String { ... }
/// ```
///
/// The request handler signature above will leads to the following codes:
///
/// ```swift
/// let firstName = try req.parameter.require("firstName", as: String.self)
/// let middleName = req.parameter.get("middleName", as: String.self)
/// let lastName = req.parameter.get("last_name", as: String.self) ?? ""
/// ```
///
/// - Note: This property wrapper only works as a marker for macro expansion, it itself does
/// nothing
@propertyWrapper
public struct PathParam<Value> {
    public var wrappedValue: Value
    private let name: String?
    public init(wrappedValue defaultValue: Value, name: String? = nil) {
        self.wrappedValue = defaultValue
        self.name = name
    }
}


/// A property wrapper denoting a parameter of a request handler function to have its value
/// retrived from the `query` property using a key
///
/// - Parameter name: specify the key for extracting the parameter from request, if the key
/// is not the same as the paramter name
///
/// ```swift
/// @EndPoint
/// func endPoint1(
///     @QueryParam firstName: String
///     @QueryParam middleName: String?
///     @QueryParam(name: "last_name") lastName: String = ""
/// ) -> String { ... }
/// ```
///
/// The request handler signature above will leads to the following codes:
///
/// ```swift
/// let firstName = try req.query.get(String.self, at: "firstName")
/// let middleName = req.query[String.self, at: "middleName"]
/// let lastName = req.query[String.self, at: "last_name"] ?? ""
/// ```
///
/// - Note: This property wrapper only works as a marker for macro expansion, it itself does
/// nothing
@propertyWrapper
public struct QueryParam<Value> {
    public var wrappedValue: Value
    private let name: String?
    public init(wrappedValue defaultValue: Value, name: String? = nil) {
        self.wrappedValue = defaultValue
        self.name = name
    }
}


/// A property wrapper denoting a parameter of a request handler function to have its value
/// retrived from the `query` property by decoding the whole query
///
/// ```swift
/// @EndPoint
/// func endPoint1(@QueryContent book: Book) throws -> HTTPStatus { ... }
/// @EndPoint
/// func endPoint2(@QueryContent book: Book?) throws -> HTTPStatus { ... }
/// @EndPoint
/// func endPoint3(@QueryContent book: Book = .default) throws -> HTTPStatus { ... }
/// ```
///
/// The request handler signature above will leads to the following codes:
///
/// ```swift
/// // endPoint1
/// let book = try req.query.decode(Book.self)
/// // endPoint2
/// let book = try? req.query.decode(Book.self)
/// // endPoint3
/// let book = (try? req.query.decode(Book.self)) ?? .default
/// ```
///
/// - Note: This property wrapper only works as a marker for macro expansion, it itself does
/// nothing
@propertyWrapper
public struct QueryContent<Value: Content>: Content {
    public var wrappedValue: Value
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}


/// A property wrapper denoting a parameter of a request handler function to have its value
/// retrived from the `auth` property of the request
///
/// ```swift
/// @EndPoint
/// func endPoint1(@AuthContent user: User) throws -> HTTPStatus { ... }
/// @EndPoint
/// func endPoint2(@AuthContent user: User?) throws -> HTTPStatus { ... }
/// @EndPoint
/// func endPoint3(@AuthContent user: User = .default) throws -> HTTPStatus { ... }
/// ```
///
/// The request handler signature above will leads to the following codes:
///
/// ```swift
/// // endPoint1
/// let user = try req.auth.require(User.self)
/// // endPoint2
/// let user = req.auth.get(User.self)
/// // endPoint3
/// let user = req.auth.get(User.self) ?? .default
/// ```
///
/// - Note: This property wrapper only works as a marker for macro expansion, it itself does
/// nothing
@propertyWrapper
public struct AuthContent<Value> {
    public var wrappedValue: Value
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}


/// A property wrapper denoting a parameter of a request handler function to get its value
/// from request using the provided `keyPath`
///
/// This is used to get values from request that are not directly support by other
/// parameter markers, such as the `db` property provided by the Fluent framework
///
/// ```swift
/// @EndPoint
/// func endPoint1(@RequestKeyPath(\.db) db: any Database) -> HTTPStatus { ... }
/// ```
///
/// The request handler signature above will leads to the following codes:
///
/// ```swift
/// let db = req[keyPath: \.db]
/// ```
///
/// If you want to get the whole Request instance, pass in `\.self`
@propertyWrapper
public struct RequestKeyPath<Value> {
    public var wrappedValue: Value
    public init(wrappedValue: Value, _ keyPath: KeyPath<Request, Value>) {
        self.wrappedValue = wrappedValue
    }
}
