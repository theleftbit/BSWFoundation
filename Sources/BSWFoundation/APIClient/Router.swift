//
//  Created by Pierluigi Cifani on 08/02/2017.
//  Copyright © 2018 TheLeftBit SL. All rights reserved.
//

import Foundation

// MARK:- Router

extension APIClient {
    
    struct Router {
        
        let environment: Environment
        
        init(environment: Environment) {
            self.environment = environment
        }
        
        func urlRequest(forEndpoint endpoint: Endpoint) throws -> URLRequest {
            guard let URL = URL(string: environment.routeURL(endpoint.path)) else {
                throw APIClient.Error.malformedURL
            }

            var urlRequest = URLRequest(url: URL)

            urlRequest.httpMethod = endpoint.method.rawValue
            urlRequest.allHTTPHeaderFields = endpoint.httpHeaderFields
            let userAgentValue = "\(Bundle.main.osName) - \(Bundle.main.displayName) \(Bundle.main.appVersion) (\(Bundle.main.appBuild))"
            urlRequest.setValue(userAgentValue.cleanForUserAgent, forHTTPHeaderField: "User-Agent")
            if let timeout = endpoint.timeoutInterval {
                urlRequest.timeoutInterval = timeout
            }
            switch endpoint.parameterEncoding {
            case .url:
                guard let url = urlRequest.url else {
                    throw APIClient.Error.encodingRequestFailed
                }
                guard let parameters = endpoint.parameters, !parameters.isEmpty, var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { break }
                let percentEncodedQuery = (urlComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + URLEncoding.query(parameters)
                urlComponents.percentEncodedQuery = percentEncodedQuery
                urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                urlRequest.url = urlComponents.url
            case .json:
                guard let parameters = endpoint.parameters, !parameters.isEmpty else { break }
                do {
                    let data = try JSONSerialization.data(withJSONObject: parameters, options: [JSONSerialization.WritingOptions.sortedKeys])
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    urlRequest.httpBody = data
                } catch {
                    throw APIClient.Error.encodingRequestFailed
                }
            }

            return urlRequest
        }        
    }
}

extension APIClient {
    class FileManagerWrapper {
        
        static let shared = FileManagerWrapper()
        private let fileManager = FileManager()
        private let queue = DispatchQueue(label: "\(ModuleName).APIClient.filemanager")
        
        func perform(_ block: @escaping (FileManager) -> Void) {
            queue.sync {
                block(fileManager)
            }
        }
    }
}

private enum URLEncoding {
    static func query(_ parameters: [String: Any]) -> String {
        var components: [(String, String)] = []

        for key in parameters.keys.sorted(by: <) {
            let value = parameters[key]!
            components += queryComponents(fromKey: key, value: value)
        }
        return components.map { "\($0)=\($1)" }.joined(separator: "&")
    }

    static func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
        var components: [(String, String)] = []

        if let dictionary = value as? [String: Any] {
            for (nestedKey, value) in dictionary {
                components += queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
            }
        } else if let array = value as? [Any] {
            for value in array {
                components += queryComponents(fromKey: "\(key)[]", value: value)
            }
        } else if let value = value as? NSNumber {
            if value.isBool {
                components.append((escape(key), escape((value.boolValue ? "1" : "0"))))
            } else {
                components.append((escape(key), escape("\(value)")))
            }
        } else if let bool = value as? Bool {
            components.append((escape(key), escape((bool ? "1" : "0"))))
        } else {
            components.append((escape(key), escape("\(value)")))
        }

        return components
    }

    static func escape(_ string: String) -> String {
#if os(Android)
        return string
#else
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string
#endif
    }
}

#if os(Android)
#else

private extension String {
    var cleanForUserAgent: String {
        var allowed = CharacterSet()
        allowed.formUnion(.urlPathAllowed)
        allowed.formUnion(.whitespaces)
        return String(unicodeScalars.filter { allowed.contains($0) })
    }
}

#endif
