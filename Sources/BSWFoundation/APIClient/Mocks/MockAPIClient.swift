//
//  Created by Pierluigi Cifani on 20/03/2019.
//

#if os(Android)
import FoundationEssentials
import FoundationNetworking
#else
import Foundation
#endif
import HTTPTypes

public actor MockNetworkFetcher: APIClientNetworkFetcher {

    enum Error: Swift.Error {
        case noDataProvided
    }

    public init() {}
    public var mockedData: Data!
    public var mockedStatusCode: Int = 200
    public var capturedRequest: APIClient.OutboundRequest?

    public func setMockedData(mockedData: Data) async {
        self.mockedData = mockedData
    }

    public func setMockedStatusCode(_ statusCode: Int) async {
        self.mockedStatusCode = statusCode
    }

    public func perform(_ request: APIClient.OutboundRequest) async throws -> APIClient.Response {
        guard mockedData != nil else {
            throw Error.noDataProvided
        }
        self.capturedRequest = request
        return APIClient.Response(
            data: mockedData,
            httpResponse: HTTPResponse(status: .init(code: mockedStatusCode))
        )
    }

    #if canImport(FoundationNetworking) || canImport(Darwin)
    public var capturedURLRequest: URLRequest? {
        return capturedRequest?.urlRequest
    }
    #endif
}
