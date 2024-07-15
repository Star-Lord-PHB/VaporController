//
//  VaporController+CommonHttpMethods.swift
//  
//
//  Created by Star_Lord_PHB on 2024/7/11.
//


import VaporControllerMacros
import Vapor


/// Denote an EndPoint (request handler) that use `GET` as method
/// - Parameter path: the path components of this handler
/// - Parameter middleware: the middleware used for this handler
///
/// It is basically using ``EndPoint(method:path:middleware:)`` with `method` set to `.GET`
///
/// This macro will scan through the parameters of the function attached to generate another
/// function that will correctly extract the required values from `Request` and call this handler
/// function using the extracted values
///
/// - Seealso: ``EndPoint(method:path:middleware:)``
///
/// - Attention: This macro MUST be attached to member functions of structs or classes that are
/// attached with ``Controller(path:middleware:)`` macro. And the actual expansion is done by
/// ``Controller(path:middleware:)``, thus expanding this macro will show nothing
@attached(peer)
public macro GET(path: String..., middleware: any Middleware...) = 
    #externalMacro(module: "VaporControllerMacros", type: "EndPointMacro.GETMacro")


/// Denote an EndPoint (request handler) that use `POST` as method
/// - Parameter path: the path components of this handler
/// - Parameter middleware: the middleware used for this handler
///
/// It is basically using ``EndPoint(method:path:middleware:)`` with `method` set to `.POST`
///
/// This macro will scan through the parameters of the function attached to generate another
/// function that will correctly extract the required values from `Request` and call this handler
/// function using the extracted values
///
/// - Seealso: ``EndPoint(method:path:middleware:)``
///
/// - Attention: This macro MUST be attached to member functions of structs or classes that are
/// attached with ``Controller(path:middleware:)`` macro. And the actual expansion is done by
/// ``Controller(path:middleware:)``, thus expanding this macro will show nothing
@attached(peer)
public macro POST(path: String..., middleware: any Middleware...) =
    #externalMacro(module: "VaporControllerMacros", type: "EndPointMacro.POSTMacro")


/// Denote an EndPoint (request handler) that use `PUT` as method
/// - Parameter path: the path components of this handler
/// - Parameter middleware: the middleware used for this handler
///
/// It is basically using ``EndPoint(method:path:middleware:)`` with `method` set to `.PUT`
///
/// This macro will scan through the parameters of the function attached to generate another
/// function that will correctly extract the required values from `Request` and call this handler
/// function using the extracted values
///
/// - Seealso: ``EndPoint(method:path:middleware:)``
///
/// - Attention: This macro MUST be attached to member functions of structs or classes that are
/// attached with ``Controller(path:middleware:)`` macro. And the actual expansion is done by
/// ``Controller(path:middleware:)``, thus expanding this macro will show nothing
@attached(peer)
public macro PUT(path: String..., middleware: any Middleware...) =
    #externalMacro(module: "VaporControllerMacros", type: "EndPointMacro.PUTMacro")


/// Denote an EndPoint (request handler) that use `DELETE` as method
/// - Parameter path: the path components of this handler
/// - Parameter middleware: the middleware used for this handler
///
/// It is basically using ``EndPoint(method:path:middleware:)`` with `method` set to `.DELETE`
///
/// This macro will scan through the parameters of the function attached to generate another
/// function that will correctly extract the required values from `Request` and call this handler
/// function using the extracted values
///
/// - Seealso: ``EndPoint(method:path:middleware:)``
///
/// - Attention: This macro MUST be attached to member functions of structs or classes that are
/// attached with ``Controller(path:middleware:)`` macro. And the actual expansion is done by
/// ``Controller(path:middleware:)``, thus expanding this macro will show nothing
@attached(peer)
public macro DELETE(path: String..., middleware: any Middleware...) =
    #externalMacro(module: "VaporControllerMacros", type: "EndPointMacro.DELETEMacro")


/// Denote an EndPoint (request handler) that use `MOVE` as method
/// - Parameter path: the path components of this handler
/// - Parameter middleware: the middleware used for this handler
///
/// It is basically using ``EndPoint(method:path:middleware:)`` with `method` set to `.MOVE`
///
/// This macro will scan through the parameters of the function attached to generate another
/// function that will correctly extract the required values from `Request` and call this handler
/// function using the extracted values
///
/// - Seealso: ``EndPoint(method:path:middleware:)``
///
/// - Attention: This macro MUST be attached to member functions of structs or classes that are
/// attached with ``Controller(path:middleware:)`` macro. And the actual expansion is done by
/// ``Controller(path:middleware:)``, thus expanding this macro will show nothing
@attached(peer)
public macro MOVE(path: String..., middleware: any Middleware...) =
    #externalMacro(module: "VaporControllerMacros", type: "EndPointMacro.MOVEMacro")


/// Denote an EndPoint (request handler) that use `COPY` as method
/// - Parameter path: the path components of this handler
/// - Parameter middleware: the middleware used for this handler
///
/// It is basically using ``EndPoint(method:path:middleware:)`` with `method` set to `.COPY`
///
/// This macro will scan through the parameters of the function attached to generate another
/// function that will correctly extract the required values from `Request` and call this handler
/// function using the extracted values
///
/// - Seealso: ``EndPoint(method:path:middleware:)``
///
/// - Attention: This macro MUST be attached to member functions of structs or classes that are
/// attached with ``Controller(path:middleware:)`` macro. And the actual expansion is done by
/// ``Controller(path:middleware:)``, thus expanding this macro will show nothing
@attached(peer)
public macro COPY(path: String..., middleware: any Middleware...) =
    #externalMacro(module: "VaporControllerMacros", type: "EndPointMacro.COPYMacro")


/// Denote an EndPoint (request handler) that use `PATCH` as method
/// - Parameter path: the path components of this handler
/// - Parameter middleware: the middleware used for this handler
///
/// It is basically using ``EndPoint(method:path:middleware:)`` with `method` set to `.PATCH`
///
/// This macro will scan through the parameters of the function attached to generate another
/// function that will correctly extract the required values from `Request` and call this handler
/// function using the extracted values
///
/// - Seealso: ``EndPoint(method:path:middleware:)``
///
/// - Attention: This macro MUST be attached to member functions of structs or classes that are
/// attached with ``Controller(path:middleware:)`` macro. And the actual expansion is done by
/// ``Controller(path:middleware:)``, thus expanding this macro will show nothing
@attached(peer)
public macro PATCH(path: String..., middleware: any Middleware...) =
    #externalMacro(module: "VaporControllerMacros", type: "EndPointMacro.PATCHMacro")


/// Denote an EndPoint (request handler) that use `HEAD` as method
/// - Parameter path: the path components of this handler
/// - Parameter middleware: the middleware used for this handler
///
/// It is basically using ``EndPoint(method:path:middleware:)`` with `method` set to `.HEAD`
///
/// This macro will scan through the parameters of the function attached to generate another
/// function that will correctly extract the required values from `Request` and call this handler
/// function using the extracted values
///
/// - Seealso: ``EndPoint(method:path:middleware:)``
///
/// - Attention: This macro MUST be attached to member functions of structs or classes that are
/// attached with ``Controller(path:middleware:)`` macro. And the actual expansion is done by
/// ``Controller(path:middleware:)``, thus expanding this macro will show nothing
@attached(peer)
public macro HEAD(path: String..., middleware: any Middleware...) =
    #externalMacro(module: "VaporControllerMacros", type: "EndPointMacro.HEADMacro")


/// Denote an EndPoint (request handler) that use `OPTIONS` as method
/// - Parameter path: the path components of this handler
/// - Parameter middleware: the middleware used for this handler
///
/// It is basically using ``EndPoint(method:path:middleware:)`` with `method` set to `.OPTIONS`
///
/// This macro will scan through the parameters of the function attached to generate another
/// function that will correctly extract the required values from `Request` and call this handler
/// function using the extracted values
///
/// - Seealso: ``EndPoint(method:path:middleware:)``
///
/// - Attention: This macro MUST be attached to member functions of structs or classes that are
/// attached with ``Controller(path:middleware:)`` macro. And the actual expansion is done by
/// ``Controller(path:middleware:)``, thus expanding this macro will show nothing
@attached(peer)
public macro OPTIONS(path: String..., middleware: any Middleware...) =
    #externalMacro(module: "VaporControllerMacros", type: "EndPointMacro.OPTIONSMacro")
