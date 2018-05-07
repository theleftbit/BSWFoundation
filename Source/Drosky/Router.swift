//
//  Created by Pierluigi Cifani on 08/02/2017.
//  Copyright © 2018 TheLeftBit SL. All rights reserved.
//

import Foundation
import Deferred
import Alamofire

// MARK:- Router

public typealias Signature = (header: String, value: String)

struct Router {
    let environment: Environment
    let signature: Signature?

    func urlRequest(forEndpoint endpoint: Endpoint) -> Task<URLRequestConvertible>.Result {
        guard let URL = URL(string: environment.routeURL(endpoint.path)) else {
            return .failure(DroskyErrorKind.malformedURLError)
        }
        
        var request = URLRequest(url: URL)
        request.httpMethod = endpoint.method.alamofireMethod().rawValue
        request.allHTTPHeaderFields = endpoint.httpHeaderFields
        if let signature = self.signature {
            request.setValue(signature.value, forHTTPHeaderField: signature.header)
        }
        
        do {
            let alamofireEncoding = endpoint.parameterEncoding.alamofireParameterEncoding()
            let request = try alamofireEncoding.encode(request, with: endpoint.parameters)
            return .success(request)
        } catch let error {
            return .failure(error)
        }
    }
}

extension HTTPMethod {
    fileprivate func alamofireMethod() -> Alamofire.HTTPMethod {
        switch self {
        case .GET:
            return .get
        case .POST:
            return .post
        case .PUT:
            return .put
        case .DELETE:
            return .delete
        case .OPTIONS:
            return .options
        case .HEAD:
            return .head
        case .PATCH:
            return .patch
        case .TRACE:
            return .trace
        case .CONNECT:
            return .connect
        }
    }
}

extension HTTPParameterEncoding {
    fileprivate func alamofireParameterEncoding() -> Alamofire.ParameterEncoding {
        switch self {
        case .url:
            return URLEncoding.default
        case .json:
            return JSONEncoding.default
        }
    }
}
