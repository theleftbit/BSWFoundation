//
//  Created by Pierluigi Cifani on 05/08/15.
//  Copyright (c) 2016 TheLeftBit SL. All rights reserved.
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
    var parameters: [String: Any]? { get }
    
    /// How the parameters should be encoded
    var parameterEncoding: HTTPParameterEncoding { get }
    
    /// The HTTP headers to be sent
    var httpHeaderFields: HTTPHeaders? { get }
}

public enum HTTPMethod: String {
    case GET, POST, PUT, DELETE, OPTIONS, HEAD, PATCH, TRACE, CONNECT
}

public enum HTTPParameterEncoding {
    case url
    case json
}

//  This is the default implementation for Endpoint 
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
}


public enum MimeType {
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


public struct MultipartParameter {
    public enum ParameterType {
        case url(URL)
        case data(Data)
    }
    
    public let parameterKey: String
    public let parameterValue: ParameterType
    public let fileName: String
    public let mimeType: MimeType
    
    public init(parameterKey: String, parameterValue: ParameterType, fileName: String, mimeType: MimeType) {
        self.parameterKey = parameterKey
        self.parameterValue = parameterValue
        self.fileName = fileName
        self.mimeType = mimeType
    }
}
