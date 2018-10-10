//
//  Created by Pierluigi Cifani on 08/02/2017.
//  Copyright © 2018 TheLeftBit SL. All rights reserved.
//

import Foundation

// MARK:- Router

extension APIClient {
    struct Router {
        let environment: Environment
        let signature: Signature?

        func urlRequest(forEndpoint endpoint: Endpoint) throws -> (URLRequest, URL?) {
            guard let URL = URL(string: environment.routeURL(endpoint.path)) else {
                throw APIClient.Error.malformedURL
            }

            var urlRequest = URLRequest(url: URL)
            var fileURL: URL?

            urlRequest.httpMethod = endpoint.method.rawValue
            urlRequest.allHTTPHeaderFields = endpoint.httpHeaderFields
            if let signature = self.signature {
                urlRequest.setValue(signature.value, forHTTPHeaderField: signature.name)
            }
            urlRequest.setValue(Bundle.main.displayName, forHTTPHeaderField: "User-Agent")

            switch endpoint.parameterEncoding {
            case .url:
                guard let url = urlRequest.url else {
                    throw APIClient.Error.encodingRequestFailed
                }
                guard let parameters = endpoint.parameters, !parameters.isEmpty, var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { break }
                let percentEncodedQuery = (urlComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + URLEncoding.query(parameters)
                urlComponents.percentEncodedQuery = percentEncodedQuery
                urlRequest.url = urlComponents.url
            case .json:
                guard let parameters = endpoint.parameters, !parameters.isEmpty else { break }
                do {
                    let data = try JSONSerialization.data(withJSONObject: parameters, options: [])
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    urlRequest.httpBody = data
                } catch {
                    throw APIClient.Error.encodingRequestFailed
                }
            case .multipart:
                guard let parameters = endpoint.parameters,
                    !parameters.isEmpty,
                    let multipartParameters = parameters as? [String: MultipartParameter]
                    else { throw APIClient.Error.malformedParameters }

                let tuple = try prepareMultipartRequest(urlRequest: urlRequest, multipartParameters: multipartParameters)
                urlRequest = tuple.0
                fileURL = tuple.1
            }

            return (urlRequest, fileURL)
        }
        
        func prepareMultipartRequest(urlRequest: URLRequest, multipartParameters: [String: MultipartParameter]) throws -> (URLRequest, URL) {
            let form = MultipartFormData()
            multipartParameters.forEach { (key, param) in
                switch param {
                case .string(let string):
                    form.append(
                        string.data(using: .utf8)!,
                        withName: key
                    )
                case .url(let url, let fileName, let mimeType):
                    form.append(
                        url,
                        withName: key,
                        fileName: fileName,
                        mimeType: mimeType.rawType
                    )
                case .data(let data, let fileName, let mimeType):
                    form.append(
                        data,
                        withName: key,
                        fileName: fileName,
                        mimeType: mimeType.rawType
                    )
                }
            }
            
            let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
            let directoryURL = tempDirectoryURL.appendingPathComponent("com.BSWFoundation.APIClient/multipart.form.data")
            let fileURL = directoryURL.appendingPathComponent(UUID().uuidString)
            
            // Create directory inside serial queue to ensure two threads don't do this in parallel
            var fileManagerError: Swift.Error?
            APIClient.FileManagerWrapper.shared.perform {
                do {
                    try APIClient.FileManagerWrapper.shared.fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                    try form.writeEncodedData(to: fileURL)
                    
                } catch {
                    fileManagerError = error
                }
            }
            
            if let fileManagerError = fileManagerError {
                throw fileManagerError
            } else {
                var urlRequestWithContentType = urlRequest
                urlRequestWithContentType.setValue(form.contentType, forHTTPHeaderField: "Content-Type")
                return (urlRequestWithContentType, fileURL)
            }
        }
    }
}

extension APIClient {
    class FileManagerWrapper {
        
        static let shared = FileManagerWrapper()
        let fileManager = FileManager.default
        let queue = DispatchQueue(label: "\(ModuleName).APIClient.filemanager")
        
        func perform(_ block: @escaping () -> Void) {
            queue.async(execute: block)
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
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string
    }
}
