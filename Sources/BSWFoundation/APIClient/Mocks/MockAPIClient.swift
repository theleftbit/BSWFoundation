//
//  Created by Pierluigi Cifani on 20/03/2019.
//

import Foundation

public actor MockNetworkFetcher: APIClientNetworkFetcher {
    
    enum Error: Swift.Error {
        case noDataProvided
    }
    
    public init() {}
    public var mockedData: Data!
    public var mockedStatusCode: Int = 200
    public var capturedURLRequest: URLRequest?
    
    public func setMockedData(mockedData: Data) async {
        self.mockedData = mockedData
    }
    
    public func setMockedStatusCode(_ statusCode: Int) async {
        self.mockedStatusCode = statusCode
    }
    
    public func fetchData(with urlRequest: URLRequest) async throws -> APIClient.Response {
        guard mockedData != nil else {
            throw Error.noDataProvided
        }
        self.capturedURLRequest = urlRequest
        let response = APIClient.Response(data: mockedData, httpResponse: HTTPURLResponse(url: urlRequest.url!, statusCode: mockedStatusCode, httpVersion: nil, headerFields: nil)!)
        return response
    }
    
    public func uploadFile(with urlRequest: URLRequest, fileURL: URL) async throws -> APIClient.Response {
        guard mockedData != nil else {
            throw Error.noDataProvided
        }
        self.capturedURLRequest = urlRequest
        let response = APIClient.Response(data: mockedData, httpResponse: HTTPURLResponse(url: urlRequest.url!, statusCode: mockedStatusCode, httpVersion: nil, headerFields: nil)!)
        return response
    }
}
