//
//  Created by Pierluigi Cifani on 05/08/15.
//  Copyright (c) 2016 TheLeftBit SL. All rights reserved.
//

#if os(Android)
import FoundationEssentials
#endif

import Foundation

// MARK: - Endpoint

/**
 Protocol used to describe what is needed
 in order to send REST API requests.
*/
public protocol Endpoint: Sendable {
    
    /// The path for the request
    var path: String { get }
    
    /// The HTTPMethod for the request
    var method: HTTPMethod { get }
    
    /// Optional parameters for the request
    var parameters: [String: Any]? { get }
    
    /// How the parameters should be encoded
    var parameterEncoding: HTTPParameterEncoding { get }
    
    /// The HTTP headers to be sent
    var httpHeaderFields: HTTPHeaders? { get }

    /// How long before the request is timed out
    var timeoutInterval: TimeInterval? { get }
    
    /// A file to upload
    var fileToUpload: URL? { get }
}

public enum HTTPMethod: String, Sendable {
    case GET, POST, PUT, DELETE, OPTIONS, HEAD, PATCH, TRACE, CONNECT
}

public enum HTTPParameterEncoding: Sendable {
    case url
    case json
}

///  This is the default implementation for Endpoint 
extension Endpoint {
    public var method: HTTPMethod {
        return .GET
    }
    
    public var parameters: [String: Any]? {
        return nil
    }
    
    public var parameterEncoding: HTTPParameterEncoding {
        return .url
    }
    
    public var httpHeaderFields: HTTPHeaders? {
        return nil
    }
    
    public var timeoutInterval: TimeInterval? {
        return nil
    }
    
    public var fileToUpload: URL? { return nil }
}


public enum MimeType: Sendable {
    case imageJPEG
    case imagePNG
    case custom(String)
    
    var rawType: String {
        switch self {
        case .imageJPEG:
            return "image/jpeg"
        case .imagePNG:
            return "image/png"
        case .custom(let mimeTypeStr):
            return mimeTypeStr
        }
    }
}
