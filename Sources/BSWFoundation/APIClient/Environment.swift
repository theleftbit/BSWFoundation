//
//  Created by Pierluigi Cifani on 29/04/16.
//  Copyright © 2018 TheLeftBit SL. All rights reserved.
//

import Foundation

/// Encapsualtes the Request to be sent to the server.
public struct Request<ResponseType>{

    public typealias Validator = (APIClient.Response) throws -> ()
    
    /// The Endpoint where to send this request.
    public let endpoint: Endpoint
    
    /// Indicates whether in case of receiving an "Unauthorized response" from the server, if it should be retried after reauthentication succeeds.
    public let shouldRetryIfUnauthorized: Bool
    
    /// An optional closure to make sure any response sent by the server to this request is valid, beyond any default validation that `APIClient` makes
    public let validator: Validator
    
    /// Initializes the Request
    /// - Parameters:
    ///   - endpoint: The Endpoint where to send this request.
    ///   - shouldRetryIfUnauthorized: Indicates whether in case of receiving an "Unauthorized response" from the server, if it should be retried after reauthentication succeeds.
    ///   - validator: An optional closure to make sure any response sent by the server to this request is valid, beyond any default validation that `APIClient` makes.
    public init(endpoint: Endpoint, shouldRetryIfUnauthorized: Bool = true, validator: @escaping Validator = { _ in }) {
        self.endpoint = endpoint
        self.validator = validator
        self.shouldRetryIfUnauthorized = shouldRetryIfUnauthorized
    }
}

/// Describes an environment to attack using a `APIClient`
public protocol Environment {
    
    /// What URL to send the requests to.
    var baseURL: URL { get }
    
    /// If HTTPS should be enforced (including Certificate validations)
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
