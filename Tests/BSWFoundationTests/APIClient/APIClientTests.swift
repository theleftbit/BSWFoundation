//
//  Created by Pierluigi Cifani on 09/02/2017.
//

import Testing
import BSWFoundation
import Foundation

actor APIClientTests {

    var sut: APIClient

    init() {
        sut = APIClient(environment: HTTPBin.Hosts.production)
    }

    @Test
    func GET() async throws {
        let ipRequest = BSWFoundation.APIClient.Request<HTTPBin.Responses.IP>(
            endpoint: HTTPBin.API.ip
        )

        let _ = try await sut.perform(ipRequest)
    }

    @Test
    func GETWithCustomValidation() async throws {
        
        let ipRequest = BSWFoundation.APIClient.Request<HTTPBin.Responses.IP>(
            endpoint: HTTPBin.API.ip,
            validator: { response in
                if response.httpResponse.statusCode != 200 {
                    throw ValidationError()
                }
        })
        
        let _ = try await sut.perform(ipRequest)
    }

    @Test
    func GETCancel() async throws {
        let ipRequest = BSWFoundation.APIClient.Request<HTTPBin.Responses.IP>(
            endpoint: HTTPBin.API.ip
        )

        let getTask = Task { try await sut.perform(ipRequest) }
        getTask.cancel()

        do {
            let _ = try await getTask.value
            Issue.record("This should fail here")
        } catch let error {
            if error is CancellationError {
                return
            } else {
                let nsError = error as NSError
                #expect(nsError.domain == NSURLErrorDomain)
                #expect(nsError.code == NSURLErrorCancelled)
            }
        }
    }

    @Test
    func upload() async throws {
        let uploadRequest = BSWFoundation.APIClient.Request<VoidResponse>(
            endpoint: HTTPBin.API.upload(generateRandomData())
        )

        let _ = try await sut.perform(uploadRequest)
    }

    @Test
    func uploadCancel() async throws {
        let uploadRequest = BSWFoundation.APIClient.Request<VoidResponse>(
            endpoint: HTTPBin.API.upload(generateRandomData())
        )

        let uploadTask = Task { try await sut.perform(uploadRequest) }
        uploadTask.cancel()

        do {
            let _ = try await uploadTask.value
            Issue.record("This should fail here")
        } catch let error {
            if error is CancellationError {
                return
            } else {
                let nsError = error as NSError
                #expect(nsError.domain == NSURLErrorDomain)
                #expect(nsError.code == NSURLErrorCancelled)
            }
        }
    }
    
    @Test
    func unauthorizedCallsRightMethod() async throws {
        let mockDelegate = await MockAPIClientDelegate()
        sut = APIClient(environment: HTTPBin.Hosts.production, networkFetcher: Network401Fetcher())
        sut.delegate = mockDelegate
        
        let ipRequest = BSWFoundation.APIClient.Request<HTTPBin.Responses.IP>(
            endpoint: HTTPBin.API.ip
        )
        // We don't care about the error here
        let _ = try? await sut.perform(ipRequest)
        let failedPath = await mockDelegate.failedPath
        #expect(failedPath != nil)
    }

    @Test
    func unauthorizedRetriesAfterGeneratingNewCredentials() async throws {
        
        actor MockAPIClientDelegateThatGeneratesNewSignature: APIClientDelegate {
            
            init(apiClient: APIClient) {
                self.apiClient = apiClient
            }
            let apiClient: APIClient
            
            func apiClientDidReceiveUnauthorized(forRequest atPath: String, apiClientID: APIClient.ID) async throws -> Bool {
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
        let mockDelegate = MockAPIClientDelegateThatGeneratesNewSignature(apiClient: sut)
        sut.delegate = mockDelegate

        let ipRequest = BSWFoundation.APIClient.Request<HTTPBin.Responses.IP>(
            endpoint: HTTPBin.API.ip
        )
        let _ = try await sut.perform(ipRequest)
    }
    
    @Test
    func customizeRequests() async throws {
        let mockNetworkFetcher = MockNetworkFetcher()
        await mockNetworkFetcher.setMockedData(mockedData: Data())
        sut = APIClient(environment: HTTPBin.Hosts.production, networkFetcher: mockNetworkFetcher)
        sut.customizeRequest = {
            var mutableURLRequest = $0
            mutableURLRequest.setValue("hello", forHTTPHeaderField: "Signature")
            return mutableURLRequest
        }
        
        let ipRequest = BSWFoundation.APIClient.Request<VoidResponse>(
            endpoint: HTTPBin.API.ip
        )

        let _ = try await sut.perform(ipRequest)
        
        guard let capturedURLRequest = await mockNetworkFetcher.capturedURLRequest else {
            throw ValidationError()
        }
        #expect(capturedURLRequest.allHTTPHeaderFields?["Signature"] == "hello")
    }
    
    @Test
    func customizeSimpleRequests() async throws {
        let mockNetworkFetcher = MockNetworkFetcher()
        await mockNetworkFetcher.setMockedData(mockedData: Data())
        sut = APIClient(environment: HTTPBin.Hosts.production, networkFetcher: mockNetworkFetcher)
        sut.customizeRequest = {
            var mutableURLRequest = $0
            mutableURLRequest.setValue("hello", forHTTPHeaderField: "Signature")
            return mutableURLRequest
        }
        
        let _ = try await sut.performSimpleRequest(forEndpoint: HTTPBin.API.ip)
        
        guard let capturedURLRequest = await mockNetworkFetcher.capturedURLRequest else {
            throw ValidationError()
        }
        #expect(capturedURLRequest.allHTTPHeaderFields?["Signature"] == "hello")
    }
}

private func generateRandomData() -> Data {
    let length = 2048
    let bytes = [UInt32](repeating: 0, count: length).map { _ in arc4random() }
    return Data(bytes: bytes, count: length)
}

@MainActor
private class MockAPIClientDelegate: NSObject, APIClientDelegate {
    func apiClientDidReceiveUnauthorized(forRequest atPath: String, apiClientID: APIClient.ID) async throws -> Bool {
        failedPath = atPath
        dispatchPrecondition(condition: .onQueue(.main))
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
