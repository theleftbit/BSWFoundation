//: [Previous](@previous)

import BSWFoundation
import XCPlayground
XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

private struct HTTPBIN: Environment {
    fileprivate var basePath: String {
        return "https://httpbin.org/"
    }
}

private enum HTTPBINAPI: Endpoint {
    case ip
    case upload

    var path: String {
        switch self {
        case .upload:
            return "post"
        case .ip:
            return "ip"
        }
    }

    var method: BSWFoundation.HTTPMethod {
        switch self {
        case .upload:
            return .POST
        default:
            return .GET
        }
    }
}

let drosky = Drosky(environment: HTTPBIN())
drosky.performRequest(forEndpoint: HTTPBINAPI.ip)
    .uponSuccess(on: .main) { (response) in
        print(response)
}

//: [Next](@next)
