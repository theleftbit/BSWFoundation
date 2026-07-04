//
//  Created by Pierluigi Cifani on 08/02/2017.
//  Copyright © 2018 TheLeftBit SL. All rights reserved.
//

#if os(Android)
import FoundationEssentials; import FoundationInternationalization
#endif
import Foundation
import HTTPTypes

// MARK:- Router

extension APIClient {

    actor Router {

        let environment: Environment
        var userAgentValue: String

        init(environment: Environment) {
            self.environment = environment
            let bundle = Bundle.main
            #if os(Android)
            self.userAgentValue = "\(bundle.osName)"
            #else
            self.userAgentValue = "\(bundle.osName) - \(bundle.displayName) \(bundle.appVersion) (\(bundle.appBuild))"
            #endif
        }

        func setUserAgentValue(_ userAgentValue: String) {
            self.userAgentValue = userAgentValue
        }

        /// Builds a transport-agnostic ``APIClient/OutboundRequest`` from the given `Endpoint`.
        ///
        /// The resulting `HTTPRequest` is assembled from URL components (scheme / authority / path)
        /// rather than a Foundation `URL` bridge, so this stays available on platforms without
        /// `FoundationNetworking` (e.g. WASM).
        func prepareRequest(forEndpoint endpoint: Endpoint) throws -> APIClient.OutboundRequest {

            // 1. Resolve the absolute URL string and encode the parameters into either the
            //    query (for `.url`) or the body (for `.json`).
            var urlString = environment.routeURL(endpoint.path)
            var body: Data?
            var contentType: String?

            switch endpoint.parameterEncoding {
            case .url:
                if let parameters = endpoint.parameters, !parameters.isEmpty {
                    let query = URLEncoding.query(parameters)
                    urlString += (urlString.contains("?") ? "&" : "?") + query
                    contentType = "application/x-www-form-urlencoded"
                }
            case .json:
                if let parameters = endpoint.parameters, !parameters.isEmpty {
                    guard let data = try? JSONSerialization.data(withJSONObject: parameters, options: [.sortedKeys]) else {
                        throw APIClient.Error.encodingRequestFailed
                    }
                    body = data
                    contentType = "application/json"
                }
            }

            // 2. Turn the URL into an `HTTPRequest`. HTTPTypes' `HTTPRequest(method:url:)` lives in
            //    the core module (behind the default-on `FoundationURL` trait), decomposes the URL
            //    into the scheme / authority / path pseudo-header fields for us — handling edge
            //    cases like IPv6 authorities — and is available on platforms without
            //    FoundationNetworking, including WASM. We pre-check the scheme because that
            //    initializer traps on a schemeless URL.
            guard let url = URL(string: urlString), url.scheme != nil else {
                throw APIClient.Error.malformedURL
            }
            guard let method = HTTPRequest.Method(endpoint.method.rawValue) else {
                throw APIClient.Error.encodingRequestFailed
            }

            // 3. Assemble the header fields. Endpoint-provided headers go in first, then the
            //    framework-managed User-Agent and Content-Type so they take precedence.
            var headerFields = HTTPFields()
            if let httpHeaderFields = endpoint.httpHeaderFields {
                for (name, value) in httpHeaderFields {
                    guard let fieldName = HTTPField.Name(name) else { continue }
                    headerFields[fieldName] = value
                }
            }
            headerFields[.userAgent] = userAgentValue.cleanForUserAgent
            if let contentType {
                headerFields[.contentType] = contentType
            }

            let httpRequest = HTTPRequest(method: method, url: url, headerFields: headerFields)

            return APIClient.OutboundRequest(
                httpRequest: httpRequest,
                body: body,
                timeoutInterval: endpoint.timeoutInterval,
                fileToUpload: endpoint.fileToUpload
            )
        }
    }
}

enum URLEncoding {
    static func query(_ parameters: [String: Any]) -> String {
        var components: [(String, String)] = []
        for key in parameters.keys.sorted(by: <) {
            let value = parameters[key]!
            components += queryComponents(fromKey: key, value: value)
        }
        return components.map { "\($0)=\($1)" }.joined(separator: "&")
    }

    private static func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
        var components: [(String, String)] = []
        if let dictionary = value as? [String: Any] {
            for (nestedKey, value) in dictionary {
                components += queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
            }
        }
        else if let array = value as? [Any] {
            for value in array {
                components += queryComponents(fromKey: "\(key)[]", value: value)
            }
        }
        else if let value = value as? Int {
            components.append((escape(key), escape("\(value)")))
        }
        else if let bool = value as? Bool {
            components.append((escape(key), escape((bool ? "1" : "0"))))
        }
        else if let date = value as? Date {
            let dateString = isoFormatter.string(from: date)
            components.append((escape(key), escape(dateString)))
        }
        else {
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

private extension String {
    /// Cleans the string to be used in the User-Agent header by:
    /// 1. Removing specific test environment suffixes like "-β" or "-test".
    /// 2. Filtering out any characters that are not part of `urlPathAllowed` or whitespaces.
    var cleanForUserAgent: String {
        var allowed = CharacterSet()
        allowed.formUnion(.urlPathAllowed)
        allowed.formUnion(.whitespaces)

        // Step 1: Remove specific suffixes
        let cleanedSuffix = self
            .replacingOccurrences(of: "-β", with: "")
            .replacingOccurrences(of: "-test", with: "")

        // Step 2: Filter remaining characters
        return String(cleanedSuffix.unicodeScalars.filter { allowed.contains($0) })
    }
}

private nonisolated(unsafe) let isoFormatter = ISO8601DateFormatter()
