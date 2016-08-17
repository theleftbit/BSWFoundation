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

/*
 Things to improve:
 1.- Wrap the network calls in a NSOperation in order to:
 * Control how many are being sent at the same time
 * Allow to add priorities in order to differentiate user facing calls to analytics crap
 2.- Use the Timeline data in Response to calculate an average of the responses from the server
 */


// Mark: HTTP method and parameter encoding

public enum HTTPMethod: String {
    case GET, POST, PUT, DELETE, OPTIONS, HEAD, PATCH, TRACE, CONNECT
}

extension HTTPMethod {
    func alamofireMethod() -> Alamofire.HTTPMethod {
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

public enum HTTPParameterEncoding {
    case url
    case json
    case propertyList(PropertyListSerialization.PropertyListFormat, PropertyListSerialization.WriteOptions)
    case custom((URLRequestConvertible, [String: Any]?) -> (URLRequest, NSError?))
}

extension HTTPParameterEncoding {
    func alamofireParameterEncoding() -> Alamofire.ParameterEncoding {
        switch self {
        case .url:
            return .url
        case .json:
            return .json
        case .propertyList(let format, let options):
            return .propertyList(format, options)
        case .custom(let closure):
            return .custom(closure)
        }
    }
}

// MARK:- DroskyResponse

public struct DroskyResponse {
    public let statusCode: Int
    public let httpHeaderFields: [String: String]
    public let data: Data
}

extension DroskyResponse {
    func dataAsJSON() -> [String: AnyObject]? {
        let json: [String: AnyObject]?
        
        do {
            json = try JSONSerialization.jsonObject(with: self.data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject]
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


// MARK:- Router

public typealias Signature = (header: String, value: String)

struct Router {
    let environment: Environment
    let signature: Signature?
    
    func urlRequest(forEndpoint endpoint: Endpoint) -> Result<URLRequestConvertible> {
        guard let URL = URL(string: environment.routeURL(endpoint.path)) else {
            return Result<URLRequestConvertible>(error: DroskyErrorKind.malformedURLError)
        }
        
        var request = URLRequest(url: URL)
        request.httpMethod = endpoint.method.alamofireMethod().rawValue
        request.allHTTPHeaderFields = endpoint.httpHeaderFields
        if let signature = self.signature {
            request.setValue(signature.value, forHTTPHeaderField: signature.header)
        }
        
        let requestTuple = endpoint.parameterEncoding.alamofireParameterEncoding().encode(request, parameters: endpoint.parameters)
        
        if let error = requestTuple.1 {
            return Result<URLRequestConvertible>(error: error)
        } else {
            return Result<URLRequestConvertible>(requestTuple.0)
        }
    }
}

// MARK: - Drosky

public final class Drosky {
    
    fileprivate static let ModuleName = "drosky"
    fileprivate let networkManager: Alamofire.SessionManager
    fileprivate let backgroundNetworkManager: Alamofire.SessionManager
    fileprivate let queue = queueForSubmodule(Drosky.ModuleName, qualityOfService: .userInitiated)
    fileprivate let gcdQueue = DispatchQueue(label: Drosky.ModuleName, attributes: [])
    fileprivate let dataSerializer = Alamofire.Request.dataResponseSerializer()
    var router: Router
    
    public init (
        environment: Environment,
        signature: Signature? = nil,
        backgroundSessionID: String = Drosky.backgroundID(),
        trustedHosts: [String] = []) {
        
        let serverTrustPolicies = Drosky.serverTrustPoliciesDisablingEvaluationForHosts(trustedHosts)
        
        let serverTrustManager = ServerTrustPolicyManager(policies: serverTrustPolicies)
        
        networkManager = Alamofire.SessionManager(
            configuration: URLSessionConfiguration.default,
            serverTrustPolicyManager: serverTrustManager
        )
        
        backgroundNetworkManager = Alamofire.SessionManager(
            configuration: URLSessionConfiguration.background(withIdentifier: backgroundSessionID),
            serverTrustPolicyManager: serverTrustManager
        )
        router = Router(environment: environment, signature: signature)
        queue.underlyingQueue = gcdQueue
    }
    
    public func setAuthSignature(_ signature: Signature?) {
        router = Router(environment: router.environment, signature: signature)
    }

    public func setEnvironment(_ environment: Environment) {
        router = Router(environment: environment, signature: router.signature)
    }
    
    fileprivate static func serverTrustPoliciesDisablingEvaluationForHosts(_ hosts: [String]) -> [String: ServerTrustPolicy] {
        var policies = [String: ServerTrustPolicy]()
        hosts.forEach { policies[$0] = .disableEvaluation }
        return policies
    }

    public func performRequest(forEndpoint endpoint: Endpoint) -> Future<Result<DroskyResponse>> {
        return generateRequest(endpoint)
                ≈> sendRequest
                ≈> processResponse
    }

    public func performAndValidateRequest(forEndpoint endpoint: Endpoint) -> Future<Result<DroskyResponse>> {
        return performRequest(forEndpoint: endpoint)
                ≈> validateDroskyResponse
    }

    public func performMultipartUpload(forEndpoint endpoint: Endpoint, multipartParams: [MultipartParameter]) -> (Future<Result<DroskyResponse>>, Future<Progress>) {
        let generatedRequest = try! router.urlRequest(forEndpoint: endpoint).dematerialize()
        let multipartRequestTuple = performUpload(generatedRequest, multipartParameters: multipartParams)
        let processedResponse = multipartRequestTuple.0 ≈> processResponse
        return (processedResponse, multipartRequestTuple.1)
    }

    //MARK:- Internal
    fileprivate func generateRequest(_ endpoint: Endpoint) -> Future<Result<URLRequestConvertible>> {
        let deferred = Deferred<Result<URLRequestConvertible>>()
        queue.addOperation { [weak self] in
            guard let strongSelf = self else { return }
            let requestResult = strongSelf.router.urlRequest(forEndpoint: endpoint)
            deferred.fill(requestResult)
        }
        return Future(deferred)
    }
    
    
    fileprivate func sendRequest(_ request: URLRequestConvertible) -> Future<Result<(Data, HTTPURLResponse)>> {
        let deferred = Deferred<Result<(Data, HTTPURLResponse)>>()
        
        networkManager
            .request(request)
            .responseData(queue: gcdQueue) { self.processAlamofireResponse($0, deferred: deferred) }
        
        return Future(deferred)
    }
    
    fileprivate func performUpload(_ request: URLRequestConvertible, multipartParameters: [MultipartParameter]) -> (Future<Result<(Data, HTTPURLResponse)>>, Future<Progress>) {
        let deferredResponse = Deferred<Result<(Data, HTTPURLResponse)>>()
        let deferredProgress = Deferred<Progress>()
        
        backgroundNetworkManager.upload(
            request,
            multipartFormData: { (form) in
                multipartParameters.forEach { param in
                    form.appendBodyPart(fileURL: param.fileURL, name: param.parameterKey)
                }
            },
            encodingCompletion: { (result) in
                switch result {
                case .Failure(let error):
                    deferredResponse.fill(Result(error: error))
                case .Success(let request, _,  _):
                    deferredProgress.fill(request.progress)
                    request.responseData(queue: self.gcdQueue) {
                        self.processAlamofireResponse($0, deferred: deferredResponse)
                    }
                }
            }
        )
        
        return (Future(deferredResponse), Future(deferredProgress))
    }
    
    fileprivate func processResponse(_ data: NSData, urlResponse: HTTPURLResponse) -> Future<Result<DroskyResponse>> {
        
        let deferred = Deferred<Result<DroskyResponse>>()
        
        queue.addOperation {
            if let responseHeaders = urlResponse.allHeaderFields as? [String: String] {

                let droskyResponse = DroskyResponse(
                    statusCode: urlResponse.statusCode,
                    httpHeaderFields: responseHeaders,
                    data: data
                )
                
                #if DEBUG
                    if let message = JSONParser.errorMessageFromData(droskyResponse.data) {
                        print(message)
                    }
                #endif

                let result = Result(droskyResponse)
                deferred.fill(result)
            }
            else {
                deferred.fill(Result(error: DroskyErrorKind.unknownResponse))
            }
        }
        
        return Future(deferred)
    }
    
    fileprivate func validateDroskyResponse(_ response: DroskyResponse) -> Future<Result<DroskyResponse>> {
        
        let deferred = Deferred<Result<DroskyResponse>>()
        
        queue.addOperation {
            switch response.statusCode {
            case 400:
                let error = DroskyErrorKind.badRequest
                deferred.fill(Result<DroskyResponse>(error: error))
            case 401:
                let error = DroskyErrorKind.unauthorized
                deferred.fill(Result<DroskyResponse>(error: error))
            case 403:
                let error = DroskyErrorKind.forbidden
                deferred.fill(Result<DroskyResponse>(error: error))
            case 404:
                let error = DroskyErrorKind.resourceNotFound
                deferred.fill(Result<DroskyResponse>(error: error))
            case 405...499:
                let error = DroskyErrorKind.unknownResponse
                deferred.fill(Result<DroskyResponse>(error: error))
            case 500:
                let error = DroskyErrorKind.serverUnavailable
                deferred.fill(Result<DroskyResponse>(error: error))
            default:
                deferred.fill(Result<DroskyResponse>(response))
            }
        }
        
        return Future(deferred)
    }

    fileprivate func processAlamofireResponse(_ response: Alamofire.Response<Data, NSError>, deferred: Deferred<Result<(Data, HTTPURLResponse)>>) {
        switch response.result {
        case .failure(let error):
            deferred.fill(Result(error: error))
        case .success(let data):
            guard let response = response.response else { fatalError() }
            deferred.fill(Result(value: (data, response)))
        }
    }
}

//MARK: Background handling

extension Drosky {
    
    fileprivate static func backgroundID() -> String {
        let appName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? Drosky.ModuleName
        return "\(appName)-\(Foundation.UUID().uuidString)"
    }

    public var backgroundSessionID: String {
        get {
            guard let sessionID = backgroundNetworkManager.session.configuration.identifier else { fatalError("This should have a sessionID") }
            return sessionID
        }
    }
    
    public func completedBackgroundTasksURL() -> Future<[NSURL]> {
        
        let deferred = Deferred<[URL]>()
        
        backgroundNetworkManager.delegate.sessionDidFinishEventsForBackgroundURLSession = { session in
            
            session.getTasksWithCompletionHandler { (dataTasks, _, _) -> Void in
                let completedTasks = dataTasks.filter { $0.state == .Completed && $0.originalRequest?.URL != nil}
                deferred.fill(completedTasks.map { return $0.originalRequest!.URL!})
                self.backgroundNetworkManager.backgroundCompletionHandler?()
            }
        }
        
        return Future(deferred)
    }

}

//MARK:- Errors

public enum DroskyErrorKind: Error {
    case unknownResponse
    case unauthorized
    case serverUnavailable
    case resourceNotFound
    case formattedError
    case malformedURLError
    case forbidden
    case badRequest
}
