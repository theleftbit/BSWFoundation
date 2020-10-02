//
//  Created by Pierluigi Cifani on 07/05/2018.
//

import XCTest
@testable import BSWFoundation

class RouterTests: XCTestCase {

    func testSimpleURLEncoding() throws {
        let sut = APIClient.Router(environment: Giphy.Hosts.production)
        let urlRequest = try sut.urlRequest(forEndpoint: Giphy.API.search("hola")).0
        guard let url = urlRequest.url else {
            throw Error.objectUnwrappedFailed
        }
        XCTAssert(url.absoluteString == "https://api.giphy.com/v1/gifs/search?q=hola")
        XCTAssert(urlRequest.allHTTPHeaderFields?["Content-Type"] == "application/x-www-form-urlencoded")
    }

    func testComplicatedURLEncoding() throws {
        let sut = APIClient.Router(environment: Giphy.Hosts.production)
        let urlRequest = try sut.urlRequest(forEndpoint: Giphy.API.search("hola guapa")).0
        guard let url = urlRequest.url else {
            throw Error.objectUnwrappedFailed
        }
        XCTAssert(url.absoluteString == "https://api.giphy.com/v1/gifs/search?q=hola%20guapa")
    }

    func testJSONEncoding() throws {
        let sut = APIClient.Router(environment: HTTPBin.Hosts.production)
        let endpoint = HTTPBin.API.orderPizza
        typealias PizzaRequestParams = [String: [String]]

        let urlRequest = try sut.urlRequest(forEndpoint: endpoint).0
        guard let url = urlRequest.url, let data = urlRequest.httpBody else {
            throw Error.objectUnwrappedFailed
        }

        XCTAssert(url.absoluteString == "https://httpbin.org/forms/post")

        guard
            let jsonParam = try JSONSerialization.jsonObject(with: data, options: []) as? PizzaRequestParams,
            let endpointParams = endpoint.parameters as? PizzaRequestParams else {
            throw Error.objectUnwrappedFailed
        }
        XCTAssert(jsonParam == endpointParams)
    }
}
