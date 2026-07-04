//
//  Created by Pierluigi Cifani on 07/05/2018.
//
#if canImport(Testing)
import Testing
@testable import BSWFoundation
import Foundation
import HTTPTypes

actor RouterTests {

    @Test
    func queryParams() async throws {
        let result = URLEncoding.query([
            "hello": true,
            "cruel": 1,
            "world": "asda",
            "what": "https://www.theleftbit.com/",
            "are": Date(timeIntervalSince1970: 1751979655),
        ])
        #expect(result == "are=2025-07-08T13%3A00%3A55Z&cruel=1&hello=1&what=https%3A//www.theleftbit.com/&world=asda")
    }

    @Test
    func defaultUserAgentGeneration() async throws {
        let sut = APIClient.Router(environment: Giphy.Hosts.production)
        let outbound = try await sut.prepareRequest(forEndpoint: Giphy.API.search("hola"))
        let userAgent = try #require(outbound.httpRequest.headerFields[.userAgent])
        #expect(userAgent.contains(Bundle.main.osName))
    }

    @Test
    func customUserAgentGeneration() async throws {
        let sut = APIClient.Router(environment: Giphy.Hosts.production)
        await sut.setUserAgentValue("Foo")
        let outbound = try await sut.prepareRequest(forEndpoint: Giphy.API.search("hola"))
        let userAgent = try #require(outbound.httpRequest.headerFields[.userAgent])
        #expect(userAgent == "Foo")
    }

    @Test
    func simpleURLEncoding() async throws {
        let sut = APIClient.Router(environment: Giphy.Hosts.production)
        let outbound = try await sut.prepareRequest(forEndpoint: Giphy.API.search("hola"))
        #expect(outbound.httpRequest.scheme == "https")
        #expect(outbound.httpRequest.authority == "api.giphy.com")
        #expect(outbound.httpRequest.path == "/v1/gifs/search?q=hola")
        #expect(outbound.httpRequest.headerFields[.contentType] == "application/x-www-form-urlencoded")
    }

    @Test
    func complicatedURLEncoding() async throws {
        let sut = APIClient.Router(environment: Giphy.Hosts.production)
        let outbound = try await sut.prepareRequest(forEndpoint: Giphy.API.search("hola guapa"))
        #expect(outbound.httpRequest.path == "/v1/gifs/search?q=hola%20guapa")
    }

    @Test
    func JSONEncoding() async throws {
        let sut = APIClient.Router(environment: HTTPBin.Hosts.production)
        let endpoint = HTTPBin.API.orderPizza
        typealias PizzaRequestParams = [String: [String]]

        let outbound = try await sut.prepareRequest(forEndpoint: endpoint)
        let data = try #require(outbound.body)
        #expect(outbound.httpRequest.authority == "httpbin.org")
        #expect(outbound.httpRequest.path == "/forms/post")

        let jsonParam = try #require(JSONSerialization.jsonObject(with: data, options: []) as? PizzaRequestParams)
        let endpointParams = try #require(endpoint.parameters as? PizzaRequestParams)

        #expect(jsonParam == endpointParams)
    }
}
#endif
