//
//  Created by Pierluigi Cifani on 07/05/2018.
//

import BSWFoundation
import Foundation

enum Error: Swift.Error {
    case objectUnwrappedFailed
}

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
        case orderPizza(useCodable: Bool)
        case upload(Data)

        var path: String {
            switch self {
            case .upload:
                return "/post"
            case .orderPizza:
                return "/forms/post"
            case .ip:
                return "/ip"
            }
        }

        var method: HTTPMethod {
            switch self {
            case .upload:
                return .POST
            case .orderPizza:
                return .POST
            default:
                return .GET
            }
        }

        var parameterEncoding: HTTPParameterEncoding {
            switch self {
            case .orderPizza:
                return .json
            case .upload:
                return .multipart
            default:
                return .url
            }
        }
        
        var encodableParameters: Encodable? {
            switch self {
            case .orderPizza(let useCodable):
                guard useCodable else { return nil }
                return Pizza(topping: ["peperoni", "olives"])
            default:
                return nil
            }
        }

        var parameters: [String : Any]? {
            switch self {
            case .upload(let data):
                return [
                    "key" : MultipartParameter.data(data, fileName: UUID().uuidString, mimeType: .imageJPEG)
                ]
            case .orderPizza(let useCodable):
                guard !useCodable else { return nil }
                return [
                    "topping": ["peperoni", "olives"]
                ]
            default:
                return nil
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

enum Giphy {
    enum Hosts: Environment {
        case production

        var baseURL: URL {
            switch self {
            case .production:
                return URL(string: "https://api.giphy.com")!
            }
        }
    }

    enum API: Endpoint {
        case trending
        case search(String)

        var path: String {
            switch self {
            case .trending:
                return "/v1/gifs/trending"
            case .search:
                return "/v1/gifs/search"
            }
        }

        var parameterEncoding: HTTPParameterEncoding {
            return .url
        }

        var parameters: [String : Any]? {
            switch self {
            case .search(let term):
                return [
                    "q": term
                ]
            default:
                return nil
            }
        }
        
        var encodableParameters: Encodable? {
            nil
        }
    }

    enum Responses {
        struct GIF: Decodable {
            let id: String
            let url: URL
            let title: String
            private enum GIFKeys: String, CodingKey {
                case id = "id"
                case images = "images"
                case title = "title"
            }

            private enum ImagesKeys: String, CodingKey {
                case original = "original"
            }

            private enum ImageKeys: String, CodingKey {
                case url = "url"
            }

            init(id: String, url: URL, title: String) {
                self.id = id
                self.url = url
                self.title = title
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: GIFKeys.self)
                let id: String = try container.decode(String.self, forKey: .id)
                let title: String = try container.decode(String.self, forKey: .title)
                let imagesContainer = try container.nestedContainer(keyedBy: ImagesKeys.self, forKey: .images)
                let originalContainer = try imagesContainer.nestedContainer(keyedBy: ImageKeys.self, forKey: .original)
                let url: URL = try originalContainer.decode(URL.self, forKey: .url)
                self.init(id: id, url: url, title: title)
            }
        }

        struct Page: Decodable {
            public let data: [GIF]
        }
    }
}

struct Pizza: Codable {
    let topping: [String]
}
