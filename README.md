# Vapor Controller 

A Swift Packages providing macros for easily writing Controllers in [Vapor](https://github.com/vapor/vapor) framework

## Usage 

A typical Vapor Controller may looks like the following: 

```swift
struct Controller: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped("endpoints")
        routes.get("say", "hello", ":firstName", ":lastName", use: sayHello(req:))
        let authRoutes = routes.grouped(User.authenticator(), User.guardMiddleware())
        authRoutes.post("login", use: login(req:))
        authRoutes.post("books", "add", use: addBook(req:))
        authRoutes.get("books", "query", use: getBooks(req:))
    }
    
    func sayHello(req: Request) throws -> String {
        let firstName = try req.parameters.require("firstName")
        let lastName = req.parameters.get("lastName") ?? ""
        return "Hello \(firstName) \(lastName)"
    }
    
    func login(req: Request) throws -> User {
        return try req.auth.require(User.self)
    }
    
    func addBook(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let book = try req.content.require(Book.self)
        // some async DB operations
        return .ok 
    }
    
    func getBooks(req: Request) async throws -> [Book] {
        let user = try req.auth.require(User.self)
        let author = req.query[String.self, at: "author"]
        let publisher = req.query[String.self, at: "publisher"]
        // some async DB operations
        return books
    }
    
}
```

Now with macros in VaporController, this can be written as follows 

```swift
@Controller(path: "endpoints")
struct Controller {
    
    @EndPoint(path: "say", "hello", ":firstName", ":lastName")
    func sayHello(firstName: String, lastName: String = "") -> String {
        return "Hello \(firstName) \(lastName)"
    }
    
    @EndPoint(method: .POST, middleware: User.authenticator(), User.guardMiddleware())
	func login(@AuthContent user: User) async throws -> User {
        return user 
    }
    
    @EndPoint(method: .POST, path: "books", "add", middleware: User.authenticator(), User.guardMiddleware())
    func addBook(@RequestBody book: Book, @AuthContent user: User) async throws -> HTTPStatus {
        // some async DB operations
        return .ok 
    }
    
    @EndPoint(path: "books", "query", middleware: User.authenticator(), User.guardMiddleware())
    func getBooks(@QueryParam author: String?, @QueryParam publisher: String?, @AuthContent user: User) async throws -> [Books] {
        // some async DB operations
        return books 
    }
    
}
```

### Denote a Controller / an EndPoint 

The following macros are provided to denote a Controller or an EndPoint (request handler)

* `Controller(path:middleware:)` macro: attach to any struct or class to denote a Controller. It will automatically conform the type to `RouteCollection` protocol and implement the `boot(routes:)` method. The `path` and `middleware` varargs specify the global path and middleware for all the handler functions in this Controller 
* `EndPoint(method:path:middleware:)` macro: attach to any member functions within a class / struct with `Controller` macro attached to denote an EndPoint (request handler). It will scan through the parameter list of the function to generate another function that will extract required data from `Request` and then call your function. It can also recognize optional type and default values to properly extract data from `Request`. The default value for the `method` parameter is `GET`  
* `CustomEndPoint(method:path:middleware:)` macro: similar to `EndPoint(path:middleware:)`, but it requires that the handler to receive one and only one `Request` instance as parameter 
* `CustomRouteBuilder(useControllerGlobalSetting:)` macro: denote a fully custom route builder function that will receive one and only one `RoutesBuilder` instance. It is basically another `boot(routes:)` function that will be called by the `boot(routes:)` function. The `useControllerGlobalSetting` parameter specify whether the provided route builder will apply the global path and middleware specified by the `Controller(path:middleware:)` macro. The default value is `false` 

### Specify where the parameter will be retrieved 

The parameters for the handler functions may come from different places in `Request` , thus 5 property wrappers are provided to denote that. These property wrappers are just for annotating the parameter and will do nothing. Using them instead of macro is because there is currently no attached macro type for function parameters 

* `PathParam`: denote that the parameter will be retrieved from the `parameter` property of `Request`. This is the default one, so if you don't add any property wrapper for a parameter, it will automatically be `PathParam` 
* `RequestBody`: denote that the parameter will be retrieved from the `content` property of `Request` 
* `QueryParam`: denote that the parameter will be retrieved from the `query` property of `Request` using `get` or subscript 
* `QueryContent`: denote that the parameter will be retrieved from the `query` property of `Request` using `decode` method 
* `AuthContent`: denote that the parameter will be retrieved from the `auth` property of `Request` 

### Optional Parameter & Default Value

Optional type and default value of the parameters of the handler function will be recognized by the `EndPoint(path:middleware:)` macro and handled correctly. Take `PathParam` as an example: 

* Non-optional type with no default value: `req.parameter.require("name", as: Type.self)`
* Optional type with no default value: `req.parameter.get("name", as: Type.self)`
* With default value: `req.parameter.get("name", as: Type.self) ?? defaultValue` 

In real code, the first function is equivalent to the second one: 

```swift
@EndPoint
func handler1(param1: Int, param2: Int?, param3: Int = 1) -> HTTPStatus { ... }

func handler(req: Request) -> HTTPStatus {
    let param1 = try req.parameter.require("param1", as: Int.self)
    let param2 = req.parameter.get("param2", as: Int.self)
    let param3 = req.parameter.get("param2", as: Int.self) ?? 1
    ...
}
```

