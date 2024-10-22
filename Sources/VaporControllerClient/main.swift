import VaporController
import Vapor

func getMethod() -> HTTPMethod { .OPTIONS }

@Controller(path: "base", "path", middleware: UserAuthenticator())
struct HHH {
    
    @EndPoint(method: .POST, path: "endpoint")
    func endPoint1(name: String = "Paul", age: Int) -> String {
        return "hello"
    }
    
    @EndPoint
    func endPoint2(_ userName: String, pass password: String?) async -> HTTPStatus {
        return .ok
    }
    
    @EndPoint(method: getMethod(), middleware: UserAuthenticator(), User.guardMiddleware())
    func endPoint3(@ReqContent user: User, @ReqContent book: Book?) throws -> HTTPStatus {
        return .ok
    }
    
    @EndPoint(path: "endpoints", "hello", ":name")
    func endPoint4(userName: String, @PathParam(name: "pass") password: String) -> HTTPStatus {
        return .ok
    }
    
    @EndPoint(path: "endpoints", "hello", ":name", body: .stream)
    func endPoint5(
        @QueryContent userName: String?,
        @QueryParam(name: "pass") password: String,
        @QueryParam age: Int = 0,
        @QueryParam description: String?,
        @AuthContent user: User = .init(name: "", age: 0),
        @RequestKeyPath(\.logger) logger: Logger,
        @ReqURL url: URI,
        @Req req: Request
    ) async throws -> HTTPStatus {
        return .ok
    }
    
    @EndPoint(path: "endpoint", "login")
    func endPoint6(@AuthContent user: User) -> HTTPStatus {
        .ok
    }
    
    @EndPoint(body: .collect(maxSize: 128))
    func endPoint7(@AuthContent _ user: User?, @QueryParam id: String) -> HTTPStatus {
        .ok
    }
    
    @EndPoint(path: "empty", "endpoint")
    func emptyEndPoint() -> HTTPStatus {
        .ok
    }
    
    // TODO: find a way to allow removing this @Sendable
    @Sendable
    @CustomEndPoint(method: .OPTIONS, path: "custom", "endpoint", middleware: UserAuthenticator(), body: .collect)
    func customEndPoint(request req: Request) -> HTTPStatus {
        .ok
    }
    
    @CustomRouteBuilder
    func customRouteBuilderWithoutGlobal(builder routes: RoutesBuilder) {
        routes.on(.ACL, "builder", "without", "global", use: { _ in HTTPStatus.ok })
    }
    
    
    @CustomRouteBuilder(useControllerGlobalSetting: true)
    func customRouteBuilderWithGlobal(_ routes: RoutesBuilder) throws {
        routes.on(.ACL, "builder", "with", "global", use: { _ in HTTPStatus.ok })
    }
    
    @OPTIONS(path: "options", "endPoint")
    func optionsEndPoint(name: String, age: Int) async throws -> HTTPStatus {
        return .ok
    }
    
    @PATCH(path: "patch", "endPoint")
    func patchEndPoint(name: String, age: Int) async throws -> HTTPStatus {
        return .ok
    }
    
}


//@Controller
//enum HHHH {
//    
//    @EndPoint
//    func multipleParamType(@PathParam @QueryParam name: String) -> HTTPStatus {
//        .ok
//    }
//    
//    @EndPoint
//    static func wrongTarget(name: String) -> HTTPStatus {
//        .ok
//    }
//    
//    @EndPoint
//    struct WrongTarget {}
//    
//    @CustomEndPoint
//    func wrongCustomEndPoint(request req: Request, name: String) -> HTTPStatus {
//        .ok
//    }
//    
//    @CustomEndPoint
//    func wrongCustomEndPoint() -> HTTPStatus {
//        .ok
//    }
//    
//    @CustomRouteBuilder
//    func wrongCustomRouteBuilder() {
//        
//    }
//    
//    @CustomRouteBuilder
//    func wrongCustomRouteBuilder(builder: RoutesBuilder, name: String) {
//        
//    }
//    
//    @CustomRouteBuilder
//    func wrongCustomRouteBuilderAsync(builder: RoutesBuilder) async {
//        
//    }
//    
//}

struct User: Content, Authenticatable {
    let name: String
    let age: Int
}

struct Book: Content {
    let name: String
    let authro: String
}


struct UserAuthenticator: AsyncBasicAuthenticator {
    func authenticate(basic: Vapor.BasicAuthorization, for request: Vapor.Request) async throws {
        request.auth.login(User(name: "Paul", age: 22))
    }
}


func test() async throws {
    let app = try await Application.make(Environment.detect())
    try app.register(collection: HHH())
    let request = Request(application: app, on: app.eventLoopGroup.any())
}

