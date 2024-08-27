//
//  Created by Pierluigi Cifani on 07/05/2018.
//

import Testing
@testable import BSWFoundation
import Foundation

actor RouterTests {

    @Test
    func simpleURLEncoding() async throws {
        let sut = APIClient.Router(environment: Giphy.Hosts.production)
        let urlRequest = try await sut.urlRequest(forEndpoint: Giphy.API.search("hola"))
        guard let url = urlRequest.url else {
            throw Error.objectUnwrappedFailed
        }
        #expect(url.absoluteString == "https://api.giphy.com/v1/gifs/search?q=hola")
        #expect(urlRequest.allHTTPHeaderFields?["Content-Type"] == "application/x-www-form-urlencoded")
    }

    @Test
    func complicatedURLEncoding() async throws {
        let sut = APIClient.Router(environment: Giphy.Hosts.production)
        let urlRequest = try await sut.urlRequest(forEndpoint: Giphy.API.search("hola guapa"))
        guard let url = urlRequest.url else {
            throw Error.objectUnwrappedFailed
        }
        #expect(url.absoluteString == "https://api.giphy.com/v1/gifs/search?q=hola%20guapa")
    }

    @Test
    func JSONEncoding() async throws {
        let sut = APIClient.Router(environment: HTTPBin.Hosts.production)
        let endpoint = HTTPBin.API.orderPizza
        typealias PizzaRequestParams = [String: [String]]

        let urlRequest = try await sut.urlRequest(forEndpoint: endpoint)
        guard let url = urlRequest.url, let data = urlRequest.httpBody else {
            throw Error.objectUnwrappedFailed
        }

        #expect(url.absoluteString == "https://httpbin.org/forms/post")

        guard
            let jsonParam = try JSONSerialization.jsonObject(with: data, options: []) as? PizzaRequestParams,
            let endpointParams = endpoint.parameters as? PizzaRequestParams else {
            throw Error.objectUnwrappedFailed
        }
        #expect(jsonParam == endpointParams)
    }
}
