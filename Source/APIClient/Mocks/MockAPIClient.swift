//
//  Created by Pierluigi Cifani on 20/03/2019.
//

import Foundation
import Deferred

public class MockNetworkFetcher: APIClientNetworkFetcher {
    
    public var mockedData: Data!
    public var mockedStatusCode: Int = 200
    
    public func fetchData(with urlRequest: URLRequest) -> Task<APIClient.Response> {
        let response = APIClient.Response(data: mockedData, httpResponse: HTTPURLResponse(url: urlRequest.url!, statusCode: mockedStatusCode, httpVersion: nil, headerFields: nil)!)
        return Task(success: response)
    }
    
    public func uploadFile(with urlRequest: URLRequest, fileURL: URL) -> Task<APIClient.Response> {
        let response = APIClient.Response(data: mockedData, httpResponse: HTTPURLResponse(url: urlRequest.url!, statusCode: mockedStatusCode, httpVersion: nil, headerFields: nil)!)
        return Task(success: response)
    }
}
