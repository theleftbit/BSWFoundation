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
    
    public var parameters: [String : AnyObject]? {
        return nil
    }
    
    public var parameterEncoding: HTTPParameterEncoding {
        return .url
    }
    
    public var httpHeaderFields: [String : String]? {
        return nil
    }
}


public struct MultipartParameter {
    public enum ParameterType {
        case url(URL)
        case data(Data)
    }
    
    public let parameterKey: String
    public let parameterValue: ParameterType
    
    public init(parameterKey: String, parameterValue: ParameterType) {
        self.parameterKey = parameterKey
        self.parameterValue = parameterValue
    }
}
