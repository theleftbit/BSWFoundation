//
//  Created by Pierluigi Cifani on 29/04/16.
//  Copyright © 2018 TheLeftBit SL. All rights reserved.
//

import Foundation

public struct Request<ResponseType>{

    public typealias Validator = (APIClient.Response) throws -> ()

    public let endpoint: Endpoint
    public let shouldRetryIfUnauthorized: Bool
    public let validator: Validator
    public init(endpoint: Endpoint, shouldRetryIfUnauthorized: Bool = true, validator: @escaping Validator = { _ in }) {
        self.endpoint = endpoint
        self.validator = validator
        self.shouldRetryIfUnauthorized = shouldRetryIfUnauthorized
    }
}

public protocol Environment {
    var baseURL: URL { get }
    var shouldAllowInsecureConnections: Bool { get }
}

public extension Environment {
    func routeURL(_ pathURL: String) -> String {
        return baseURL.absoluteString + pathURL
    }

    var shouldAllowInsecureConnections: Bool {
        return false
    }
}
