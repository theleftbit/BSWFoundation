//
//  Created by Pierluigi Cifani on 05/08/15.
//  Copyright (c) 2016 Blurred Software SL. All rights reserved.
//

import Foundation

// MARK: - Endpoint

/**
 Protocol used to describe what is needed
 in order to send REST API requests.
*/
public protocol Endpoint {
    
    /// The path for the request
    var path: String { get }
    
    /// The HTTPMethod for the request
    var method: HTTPMethod { get }
    
    /// Optional parameters for the request
    var parameters: [String : AnyObject]? { get }
    
    /// How the parameters should be encoded
    var parameterEncoding: HTTPParameterEncoding { get }
    
    /// The HTTP headers to be sent
    var httpHeaderFields: [String : String]? { get }
}

//  This is the default implementation for Endpoint 
extension Endpoint {
    public var method: HTTPMethod {
        return .GET
    }
    
    var parameters: [String : AnyObject]? {
        return nil
    }
    
    public var parameterEncoding: HTTPParameterEncoding {
        return .URL
    }
    
    public var httpHeaderFields: [String : String]? {
        return nil
    }
}

// MARK: Endpoint collections (aka API)

public protocol EndpointCollection: Endpoint {
    var currentEndpoint: Endpoint { get }
}

extension EndpointCollection {
    public var path: String {
        return currentEndpoint.path
    }
    
    public var method: HTTPMethod {
        return currentEndpoint.method
    }
    
    public var parameters: [String : AnyObject]? {
        return currentEndpoint.parameters
    }
    
    public var parameterEncoding: HTTPParameterEncoding {
        return currentEndpoint.parameterEncoding
    }
    
    public var httpHeaderFields: [String : String]? {
        return currentEndpoint.httpHeaderFields
    }
}
