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
    func endPoint3(@RequestBody user: User) -> HTTPStatus {
        return .ok
    }
    
    @EndPoint(path: "endpoints", "hello", ":name")
    func endPoint4(userName: String, @PathParam(name: "pass") password: String) -> HTTPStatus {
        return .ok
    }
    
    @EndPoint(path: "endpoints", "hello", ":name")
    func endPoint5(
        @QueryContent userName: String,
        @QueryParam(name: "pass") password: String,
        @QueryParam age: Int = 0,
        @QueryParam description: String?
    ) async -> HTTPStatus {
        return .ok
    }
    
    @EndPoint(path: "empty", "endpoint")
    func emptyEndPoint() -> HTTPStatus {
        .ok
    }
    
    @CustomEndPoint(method: .OPTIONS, path: "custom", "endpoint", middleware: UserAuthenticator())
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


struct UserAuthenticator: AsyncBasicAuthenticator {
    func authenticate(basic: Vapor.BasicAuthorization, for request: Vapor.Request) async throws {
        request.auth.login(User(name: "Paul", age: 22))
    }
}


func test() async throws {
    let app = try await Application.make(Environment.detect())
    try app.register(collection: HHH())
}

