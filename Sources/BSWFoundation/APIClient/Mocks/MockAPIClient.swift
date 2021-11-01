//
//  Created by Pierluigi Cifani on 20/03/2019.
//

import Foundation
import Task

public class MockNetworkFetcher: APIClientNetworkFetcher {
    
    public init() {}
    public var mockedData: Data!
    public var mockedStatusCode: Int = 200
    public var capturedURLRequest: URLRequest?
    
    public func fetchData(with urlRequest: URLRequest) async throws -> APIClient.Response {
        self.capturedURLRequest = urlRequest
        let response = APIClient.Response(data: mockedData, httpResponse: HTTPURLResponse(url: urlRequest.url!, statusCode: mockedStatusCode, httpVersion: nil, headerFields: nil)!)
        return response
    }
    
    public func uploadFile(with urlRequest: URLRequest, fileURL: URL) async throws -> APIClient.Response {
        self.capturedURLRequest = urlRequest
        let response = APIClient.Response(data: mockedData, httpResponse: HTTPURLResponse(url: urlRequest.url!, statusCode: mockedStatusCode, httpVersion: nil, headerFields: nil)!)
        return response
    }
}
