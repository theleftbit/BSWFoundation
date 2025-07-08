//
//  Created by Pierluigi Cifani on 07/05/2018.
//
#if canImport(Testing)
import Testing
@testable import BSWFoundation
import Foundation

actor RouterTests {

    @Test
    func defaultUserAgentGeneration() async throws {
        let sut = APIClient.Router(environment: Giphy.Hosts.production)
        let urlRequest = try await sut.urlRequest(forEndpoint: Giphy.API.search("hola"))
        let userAgent = try #require(urlRequest.allHTTPHeaderFields?["User-Agent"])
        #expect(userAgent.contains(Bundle.main.osName))
    }
    
    @Test
    func customUserAgentGeneration() async throws {
        let sut = APIClient.Router(environment: Giphy.Hosts.production)
        await sut.setUserAgentValue("Foo")
        let urlRequest = try await sut.urlRequest(forEndpoint: Giphy.API.search("hola"))
        let userAgent = try #require(urlRequest.allHTTPHeaderFields?["User-Agent"])
        #expect(userAgent == "Foo")
    }
    
    @Test
    func simpleURLEncoding() async throws {
        let sut = APIClient.Router(environment: Giphy.Hosts.production)
        let urlRequest = try await sut.urlRequest(forEndpoint: Giphy.API.search("hola"))
        let url = try #require(urlRequest.url)
        #expect(url.absoluteString == "https://api.giphy.com/v1/gifs/search?q=hola")
        #expect(urlRequest.allHTTPHeaderFields?["Content-Type"] == "application/x-www-form-urlencoded")
    }

    @Test
    func complicatedURLEncoding() async throws {
        let sut = APIClient.Router(environment: Giphy.Hosts.production)
        let urlRequest = try await sut.urlRequest(forEndpoint: Giphy.API.search("hola guapa"))
        let url = try #require(urlRequest.url)
        #expect(url.absoluteString == "https://api.giphy.com/v1/gifs/search?q=hola%20guapa")
    }

    @Test
    func JSONEncoding() async throws {
        let sut = APIClient.Router(environment: HTTPBin.Hosts.production)
        let endpoint = HTTPBin.API.orderPizza
        typealias PizzaRequestParams = [String: [String]]

        let urlRequest = try await sut.urlRequest(forEndpoint: endpoint)
        let url = try #require(urlRequest.url)
        let data = try #require(urlRequest.httpBody)
        #expect(url.host() == "httpbin.org")
        #expect(url.path() == "/forms/post")

        let jsonParam = try #require(JSONSerialization.jsonObject(with: data, options: []) as? PizzaRequestParams)
        let endpointParams = try #require(endpoint.parameters as? PizzaRequestParams)

        #expect(jsonParam == endpointParams)
    }
}
#endif
