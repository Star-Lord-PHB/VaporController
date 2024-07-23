//
//  HandlerParameterMarkers.swift
//  VaporController
//
//  Created by Star_Lord_PHB on 2024/7/20.
//

import Vapor


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
@available(*, deprecated, renamed: "ReqContent", message: "use @ReqContent instead")
@propertyWrapper
public struct RequestBody<T> {
    public var wrappedValue: T
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
}


/// A property wrapper denoting a parameter of a request handler function to have its value
/// retrived from the `content` property of the request
///
/// ```swift
/// @EndPoint(method: .POST)
/// func endPoint1(@ReqContent book: Book) throws -> HTTPStatus { ... }
/// @EndPoint(method: .POST)
/// func endPoint2(@ReqContent book: Book?) throws -> HTTPStatus { ... }
/// @EndPoint(method: .POST)
/// func endPoint3(@ReqContent book: Book = .default) throws -> HTTPStatus { ... }
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
public struct ReqContent<T> {
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
public struct QueryContent<Value> {
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
public struct AuthContent<Value: Authenticatable> {
    public var wrappedValue: Value
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}


/// A property wrapper denoting a parameter of a request handler function to get its value
/// from request using the provided `keyPath`
///
/// This is used to get values from request that are not directly support by other
/// parameter markers, such as the `db` property provided by the Fluent framework.
///
/// The default key path is `\.self`
///
/// ```swift
/// @EndPoint
/// func endPoint1(@Req(\.db) db: any Database) -> HTTPStatus { ... }
///
/// @EndPoint
/// func endPoint2(@Req req: Request) -> HTTPStatus { ... }
/// ```
///
/// The request handler signature above will leads to the following codes:
///
/// ```swift
/// // endPoint1
/// let db = req[keyPath: \.db]
/// // endPoint2
/// let req = req[keyPath: \.self]
/// ```
///
/// If you want to get the whole Request instance, pass in `\.self` or nothing
///
/// - Note: This property wrapper only works as a marker for macro expansion, it itself does
/// nothing
@propertyWrapper
public struct Req<Value> {
    public var wrappedValue: Value
    public init(wrappedValue: Value, _ keyPath: KeyPath<Request, Value> = \.self) {
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
///
/// - Note: This property wrapper only works as a marker for macro expansion, it itself does
/// nothing
@available(*, deprecated, renamed: "Req", message: "use @Req instead")
@propertyWrapper
public struct RequestKeyPath<Value> {
    public var wrappedValue: Value
    public init(wrappedValue: Value, _ keyPath: KeyPath<Request, Value>) {
        self.wrappedValue = wrappedValue
    }
}


/// A property wrapper denoting a parameter of a request handler function to get its value
/// from the `url` property of the request
///
/// ```swift
/// @EndPoint
/// func endPoint1(@ReqURL url: URI) -> HTTPStatus { ... }
/// ```
///
/// The request handler signature above will leads to the following codes:
///
/// ```swift
/// let url = req.url
/// ```
///
/// - Note: This property wrapper only works as a marker for macro expansion, it itself does
/// nothing
@propertyWrapper
public struct ReqURL {
    public var wrappedValue: URI
    public init(wrappedValue: URI) {
        self.wrappedValue = wrappedValue
    }
}


extension Optional: @retroactive Authenticatable where Wrapped: Authenticatable {}
