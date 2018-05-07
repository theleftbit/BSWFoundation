//
//  Created by Pierluigi Cifani on 07/05/2018.
//

import BSWFoundation

/// Full-suite tests are courtesy of our good friends of HTTPBin

enum HTTPBin {
    enum Hosts: Environment {
        case production
        case development

        var baseURL: URL {
            switch self {
            case .production:
                return URL(string: "https://httpbin.org")!
            case .development:
                return URL(string: "https://dev.httpbin.org")!
            }
        }
    }

    enum API: Endpoint {
        case ip
        case orderPizza

        var path: String {
            switch self {
            case .orderPizza:
                return "/forms/post"
            case .ip:
                return "/ip"
            }
        }

        var method: HTTPMethod {
            switch self {
            case .orderPizza:
                return .POST
            default:
                return .GET
            }
        }
    }

    enum Responses {
        struct IP: Decodable {
            let origin: String
        }
    }
}

enum BSWEnvironment: Environment {
    case production
    case staging

    var baseURL: URL {
        switch self {
        case .production:
            return URL(string: "https://theleftbit.com/")!
        case .staging:
            return URL(string: "https://staging.theleftbit.com/")!
        }
    }

    var shouldAllowInsecureConnections: Bool {
        switch self {
        case .production:
            return false
        default:
            return true
        }
    }
}
