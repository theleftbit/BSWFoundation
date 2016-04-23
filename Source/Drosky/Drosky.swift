//
//  Created by Pierluigi Cifani on 03/06/15.
//  Copyright (c) 2016 Blurred Software SL. All rights reserved.
//

import Foundation
import Alamofire
import Deferred

/*
Welcome to Drosky, your one and only way of talking to Rest APIs.

Inspired by Moya (https://github.com/AshFurrow/Moya)

*/

// Mark: HTTP method and parameter encoding

public enum HTTPMethod: String {
    case GET, POST, PUT, DELETE, OPTIONS, HEAD, PATCH, TRACE, CONNECT
}

public enum HTTPParameterEncoding {
    case URL
    case JSON
    case PropertyList(NSPropertyListFormat, NSPropertyListWriteOptions)
    case Custom((URLRequestConvertible, [String: AnyObject]?) -> (NSMutableURLRequest, NSError?))
}

extension HTTPParameterEncoding {
    func alamofireParameterEncoding() -> Alamofire.ParameterEncoding {
        switch self {
        case .URL:
            return .URL
        case .JSON:
            return .JSON
        case .PropertyList(let format, let options):
            return .PropertyList(format, options)
        case .Custom(let closure):
            return .Custom(closure)
        }
    }
}

// MARK: DroskyResponse

public struct DroskyResponse {
    let statusCode: Int
    let httpHeaderFields: [String: String]
    let data: NSData
}

extension DroskyResponse {
    func dataAsJSON() -> [String: AnyObject]? {
        let json: [String: AnyObject]?

        do {
            json = try NSJSONSerialization.JSONObjectWithData(self.data, options: NSJSONReadingOptions.AllowFragments) as? [String: AnyObject]
        } catch {
            json = nil
        }

        return json
    }
}

extension DroskyResponse: CustomStringConvertible {
    public var description: String {
        return "StatusCode: " + String(statusCode) + "\nHeaders: " +  httpHeaderFields.description
    }
}

// MARK: - Drosky

public final class Drosky {
    
    private let networkManager: Alamofire.Manager
    private let queue = queueForSubmodule("drosky")
    
    public init (configuration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()) {
            networkManager = Alamofire.Manager(configuration: configuration)
    }
    
    public func performRequest(forEndpoint endpoint: Endpoint) -> Future<Result<DroskyResponse>> {
        return generateRequest(endpoint)
                ≈> performNSURLRequest
    }
    
    public func performNSURLRequest(request: NSURLRequest) -> Future<Result<DroskyResponse>> {
        return sendRequest(request)
                ≈> validateDroskyResponse
    }
    
    // Internal
    private func generateRequest(endpoint: Endpoint) -> Future<Result<NSURLRequest>> {
        let deferred = Deferred<Result<NSURLRequest>>()
        dispatch_async(queue) { [weak self] in
            guard let welf = self else { return }
            
            let requestResult = welf.generateHTTPRequest(endpoint)
            deferred.fill(requestResult)
        }
        return Future(deferred)
    }
    
    private func generateHTTPRequest(endpoint: Endpoint) -> Result<NSURLRequest> {
        guard let URL = NSURL(string: endpoint.path) else {
            return Result<NSURLRequest>(error: DroskyErrorKind.MalformedURLError)
        }

        let request = NSMutableURLRequest(URL: URL)
        request.HTTPMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.httpHeaderFields
        
        let requestTuple = endpoint.parameterEncoding.alamofireParameterEncoding().encode(request, parameters: endpoint.parameters)
        
        if let error = requestTuple.1 {
            return Result<NSURLRequest>(error: error)
        } else {
            return Result<NSURLRequest>(requestTuple.0)
        }
    }

    private func sendRequest(request: NSURLRequest) -> Future<Result<DroskyResponse>> {
        let deferred = Deferred<Result<DroskyResponse>>()
        let dataSerializer = Alamofire.Request.dataResponseSerializer()
        
        networkManager.request(request)
            .response(queue: queue,
                responseSerializer: dataSerializer) { (response) in
                    switch response.result {
                    case .Failure(let error):
                        // TODO: Maybe parse the error data here?
                        deferred.fill(Result<DroskyResponse>(error: error))
                    case .Success(let data):
                        if let urlResponse = response.response, let responseHeaders = urlResponse.allHeaderFields as? [String: String] {
                            let response = DroskyResponse(statusCode: urlResponse.statusCode, httpHeaderFields: responseHeaders, data: data)
                            deferred.fill(Result<DroskyResponse>(response))
                        }
                        else {
                            deferred.fill(Result<DroskyResponse>(error: DroskyErrorKind.UnknownResponse))
                        }
                    }
        }
        
        return Future(deferred)
    }
    
    private func validateDroskyResponse(response: DroskyResponse) -> Future<Result<DroskyResponse>> {
        
        let deferred = Deferred<Result<DroskyResponse>>()
        
        dispatch_async(queue) {
            switch response.statusCode {
            case 400:
                let error = DroskyErrorKind.BadRequest
                deferred.fill(Result<DroskyResponse>(error: error))
            case 401:
                let error = DroskyErrorKind.Unauthorized
                deferred.fill(Result<DroskyResponse>(error: error))
            case 403:
                let error = DroskyErrorKind.Forbidden
                deferred.fill(Result<DroskyResponse>(error: error))
            case 404:
                let error = DroskyErrorKind.ResourceNotFound
                deferred.fill(Result<DroskyResponse>(error: error))
            case 405...499:
                let error = DroskyErrorKind.UnknownResponse
                deferred.fill(Result<DroskyResponse>(error: error))
            case 500:
                let error = DroskyErrorKind.ServerUnavailable
                deferred.fill(Result<DroskyResponse>(error: error))
            default:
                deferred.fill(Result<DroskyResponse>(response))
            }
        }
        
        return Future(deferred)
    }
}

//MARK:- Errors

public enum DroskyErrorKind: ResultErrorType {
    case UnknownResponse
    case Unauthorized
    case ServerUnavailable
    case ResourceNotFound
    case FormattedError
    case MalformedURLError
    case Forbidden
    case BadRequest
}
