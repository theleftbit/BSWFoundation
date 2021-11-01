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

    func testGET() throws {
        let ipRequest = BSWFoundation.Request<HTTPBin.Responses.IP>(
            endpoint: HTTPBin.API.ip
        )

        let getTask = sut.perform(ipRequest)
        let _ = try self.waitAndExtractValue(getTask, timeout: 3)
    }

    func testGETWithCustomValidation() throws {
        
        let ipRequest = BSWFoundation.Request<HTTPBin.Responses.IP>(
            endpoint: HTTPBin.API.ip,
            validator: { response in
                if response.httpResponse.statusCode != 200 {
                    throw ValidationError()
                }
        })
        
        let getTask = sut.perform(ipRequest)
        let _ = try self.waitAndExtractValue(getTask, timeout: 3)
    }

    func testGETCancel() throws {
        XCTExpectFailure()
        let ipRequest = BSWFoundation.Request<HTTPBin.Responses.IP>(
            endpoint: HTTPBin.API.ip
        )

        let getTask = sut.perform(ipRequest)
        getTask.cancel()

        do {
            let _ = try self.waitAndExtractValue(getTask)
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

    func testUpload() throws {
        let uploadRequest = BSWFoundation.Request<VoidResponse>(
            endpoint: HTTPBin.API.upload(generateRandomData())
        )

        let uploadTask = sut.perform(uploadRequest)
        var progress: ProgressObserver! = ProgressObserver(progress: uploadTask.progress) { (progress) in
            print(progress.fractionCompleted)
        }
        let _ = try self.waitAndExtractValue(uploadTask, timeout: 10)
        if let _ = progress {} /// This if-let is to to shut up the compiler
        progress = nil
    }

    func testUploadCancel() {
        XCTExpectFailure()
        let uploadRequest = BSWFoundation.Request<VoidResponse>(
            endpoint: HTTPBin.API.upload(generateRandomData())
        )

        let uploadTask = sut.perform(uploadRequest)
        uploadTask.cancel()

        do {
            let _ = try self.waitAndExtractValue(uploadTask)
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
    
    func testUnauthorizedCallsRightMethod() throws {
        let mockDelegate = MockAPIClientDelegate()
        sut = APIClient(environment: HTTPBin.Hosts.production, networkFetcher: Network401Fetcher())
        sut.delegate = mockDelegate
        
        let ipRequest = BSWFoundation.Request<HTTPBin.Responses.IP>(
            endpoint: HTTPBin.API.ip
        )
        // We don't care about the error here
        let _ = try? waitAndExtractValue(sut.perform(ipRequest))
        XCTAssert(mockDelegate.failedPath != nil)
    }

    func testUnauthorizedRetriesAfterGeneratingNewCredentials() throws {
        
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
        let _ = try waitAndExtractValue(sut.perform(ipRequest))
    }
    
    func testCustomizeRequests() throws {
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

        let _ = try waitAndExtractValue(sut.perform(ipRequest))
        
        guard let capturedURLRequest = mockNetworkFetcher.capturedURLRequest else {
            throw ValidationError()
        }
        XCTAssert(capturedURLRequest.allHTTPHeaderFields?["Signature"] == "hello")
    }
    
    func testCustomizeSimpleRequests() throws {
        let mockNetworkFetcher = MockNetworkFetcher()
        mockNetworkFetcher.mockedData = Data()
        sut = APIClient(environment: HTTPBin.Hosts.production, networkFetcher: mockNetworkFetcher)
        sut.customizeRequest = {
            var mutableURLRequest = $0
            mutableURLRequest.setValue("hello", forHTTPHeaderField: "Signature")
            return mutableURLRequest
        }
        
        let _ = try waitAndExtractValue(sut.performSimpleRequest(forEndpoint: HTTPBin.API.ip))
        
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

import Task

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
