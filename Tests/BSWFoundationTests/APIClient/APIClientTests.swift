//
//  Created by Pierluigi Cifani on 09/02/2017.
//

import XCTest
import BSWFoundation

class APIClientTests: XCTestCase {

    var sut: APIClient!

    override func setUp() {
        sut = APIClient(environment: HTTPBin.Hosts.production)
    }

    func testGET() async throws {
        let ipRequest = BSWFoundation.Request<HTTPBin.Responses.IP>(
            endpoint: HTTPBin.API.ip
        )

        let _ = try await sut.perform(ipRequest)
    }

    func testGETWithCustomValidation() async throws {
        
        let ipRequest = BSWFoundation.Request<HTTPBin.Responses.IP>(
            endpoint: HTTPBin.API.ip,
            validator: { response in
                if response.httpResponse.statusCode != 200 {
                    throw ValidationError()
                }
        })
        
        let _ = try await sut.perform(ipRequest)
    }

    func testGETCancel() async throws {
        let ipRequest = BSWFoundation.Request<HTTPBin.Responses.IP>(
            endpoint: HTTPBin.API.ip
        )

        let getTask = Task { try await sut.perform(ipRequest) }
        getTask.cancel()

        do {
            let _ = try await getTask.value
            XCTFail("This should fail here")
        } catch let error {
            if error is CancellationError {
                return
            } else {
                let nsError = error as NSError
                XCTAssert(nsError.domain == NSURLErrorDomain)
                XCTAssert(nsError.code == NSURLErrorCancelled)
            }
        }
    }

    func testUpload() async throws {
        let uploadRequest = BSWFoundation.Request<VoidResponse>(
            endpoint: HTTPBin.API.upload(generateRandomData())
        )

        let _ = try await sut.perform(uploadRequest)
    }

    func testUploadCancel() async throws {
        let uploadRequest = BSWFoundation.Request<VoidResponse>(
            endpoint: HTTPBin.API.upload(generateRandomData())
        )

        let uploadTask = Task { try await sut.perform(uploadRequest) }
        uploadTask.cancel()

        do {
            let _ = try await uploadTask.value
            XCTFail("This should fail here")
        } catch let error {
            if error is CancellationError {
                return
            } else {
                let nsError = error as NSError
                XCTAssert(nsError.domain == NSURLErrorDomain)
                XCTAssert(nsError.code == NSURLErrorCancelled)
            }
        }
    }
    
    func testUnauthorizedCallsRightMethod() async throws {
        let mockDelegate = MockAPIClientDelegate()
        sut = APIClient(environment: HTTPBin.Hosts.production, networkFetcher: Network401Fetcher())
        sut.delegate = mockDelegate
        
        let ipRequest = BSWFoundation.Request<HTTPBin.Responses.IP>(
            endpoint: HTTPBin.API.ip
        )
        // We don't care about the error here
        let _ = try? await sut.perform(ipRequest)
        XCTAssert(mockDelegate.failedPath != nil)
    }

    func testUnauthorizedRetriesAfterGeneratingNewCredentials() async throws {
        
        class MockAPIClientDelegateThatGeneratesNewSignature: APIClientDelegate {
            func apiClientDidReceiveUnauthorized(forRequest atPath: String, apiClient: APIClient) async throws -> Bool {
                apiClient.customizeRequest = { urlRequest in
                    var mutableRequest = urlRequest
                    mutableRequest.setValue("Daenerys Targaryen is the True Queen", forHTTPHeaderField: "JWT")
                    return mutableRequest
                }
                return true
            }
        }
        
        class SignatureCheckingNetworkFetcher: APIClientNetworkFetcher {
            
            public func fetchData(with urlRequest: URLRequest) async throws -> APIClient.Response {
                guard let _ = urlRequest.allHTTPHeaderFields?["JWT"] else {
                    return APIClient.Response(data: Data(), httpResponse: HTTPURLResponse(url: urlRequest.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!)
                }
                
                return try await URLSession.shared.fetchData(with: urlRequest)
            }
            
            public func uploadFile(with urlRequest: URLRequest, fileURL: URL) async throws -> APIClient.Response {
                fatalError()
            }

        }
        
        sut = APIClient(environment: HTTPBin.Hosts.production, networkFetcher: SignatureCheckingNetworkFetcher())
        let mockDelegate = MockAPIClientDelegateThatGeneratesNewSignature()
        sut.delegate = mockDelegate

        let ipRequest = BSWFoundation.Request<HTTPBin.Responses.IP>(
            endpoint: HTTPBin.API.ip
        )
        let _ = try await sut.perform(ipRequest)
    }
    
    func testCustomizeRequests() async throws {
        let mockNetworkFetcher = MockNetworkFetcher()
        mockNetworkFetcher.mockedData = Data()
        sut = APIClient(environment: HTTPBin.Hosts.production, networkFetcher: mockNetworkFetcher)
        sut.customizeRequest = {
            var mutableURLRequest = $0
            mutableURLRequest.setValue("hello", forHTTPHeaderField: "Signature")
            return mutableURLRequest
        }
        
        let ipRequest = BSWFoundation.Request<VoidResponse>(
            endpoint: HTTPBin.API.ip
        )

        let _ = try await sut.perform(ipRequest)
        
        guard let capturedURLRequest = mockNetworkFetcher.capturedURLRequest else {
            throw ValidationError()
        }
        XCTAssert(capturedURLRequest.allHTTPHeaderFields?["Signature"] == "hello")
    }
    
    func testCustomizeSimpleRequests() async throws {
        let mockNetworkFetcher = MockNetworkFetcher()
        mockNetworkFetcher.mockedData = Data()
        sut = APIClient(environment: HTTPBin.Hosts.production, networkFetcher: mockNetworkFetcher)
        sut.customizeRequest = {
            var mutableURLRequest = $0
            mutableURLRequest.setValue("hello", forHTTPHeaderField: "Signature")
            return mutableURLRequest
        }
        
        let _ = try await sut.performSimpleRequest(forEndpoint: HTTPBin.API.ip)
        
        guard let capturedURLRequest = mockNetworkFetcher.capturedURLRequest else {
            throw ValidationError()
        }
        XCTAssert(capturedURLRequest.allHTTPHeaderFields?["Signature"] == "hello")
    }
}

private func generateRandomData() -> Data {
    let length = 2048
    let bytes = [UInt32](repeating: 0, count: length).map { _ in arc4random() }
    return Data(bytes: bytes, count: length)
}

private class MockAPIClientDelegate: APIClientDelegate {
    func apiClientDidReceiveUnauthorized(forRequest atPath: String, apiClient: APIClient) async throws -> Bool {
        failedPath = atPath
        return false
    }
    var failedPath: String?
}

private class Network401Fetcher: APIClientNetworkFetcher {
    
    public func fetchData(with urlRequest: URLRequest) async throws -> APIClient.Response {
        return APIClient.Response(data: Data(), httpResponse: HTTPURLResponse(url: urlRequest.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!)
    }
    
    public func uploadFile(with urlRequest: URLRequest, fileURL: URL) async throws -> APIClient.Response {
        fatalError()
    }
}

struct ValidationError: Swift.Error {}
