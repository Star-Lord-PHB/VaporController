// The Swift Programming Language
// https://docs.swift.org/swift-book

import VaporControllerMacros
import Vapor
import SwiftUI


@attached(peer)
public macro EndPoint(method: Vapor.HTTPMethod = .GET, path: String..., middleware: any Middleware...) =
    #externalMacro(module: "VaporControllerMacros", type: "EndPointMacro")



@attached(extension, conformances: RouteCollection, names: arbitrary)
public macro Controller(path: String..., middleware: any Middleware...) =
    #externalMacro(module: "VaporControllerMacros", type: "ControllerMacro")



//@attached(peer)
//public macro RequestBody() = #externalMacro(module: "VaporControllerMacros", type: "RequestBodyMacro")


@attached(peer)
public macro CustomEndPoint(method: Vapor.HTTPMethod = .GET, path: String..., middleware: any Middleware...) =
    #externalMacro(module: "VaporControllerMacros", type: "CustomEndPointMacro")


@attached(peer)
public macro CustomRouteBuilder(useControllerGlobalSetting: Bool = false) =
    #externalMacro(module: "VaporControllerMacros", type: "CustomRouteBuilderMacro")



@propertyWrapper
public struct RequestBody<T: Content>: Content {
    public var wrappedValue: T
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
}


@propertyWrapper 
public struct PathParam<Value> {
    public var wrappedValue: Value
    private let name: String?
    public init(wrappedValue defaultValue: Value, name: String? = nil) {
        self.wrappedValue = defaultValue
        self.name = name
    }
}


@propertyWrapper
public struct QueryParam<Value> {
    public var wrappedValue: Value
    private let name: String?
    public init(wrappedValue defaultValue: Value, name: String? = nil) {
        self.wrappedValue = defaultValue
        self.name = name
    }
}


@propertyWrapper
public struct QueryContent<Value: Content>: Content {
    public var wrappedValue: Value
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}
