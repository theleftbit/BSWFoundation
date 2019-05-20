//
//  Created by Pierluigi Cifani on 09/02/2017.
//

import XCTest
import BSWFoundation

class APIClientTests: XCTestCase {

    var sut = APIClient(environment: HTTPBin.Hosts.production)

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
        let ipRequest = BSWFoundation.Request<HTTPBin.Responses.IP>(
            endpoint: HTTPBin.API.ip
        )

        let getTask = sut.perform(ipRequest)
        getTask.cancel()

        do {
            let _ = try self.waitAndExtractValue(getTask)
            XCTFail("This should fail here")
        } catch let error {
            let nsError = error as NSError
            XCTAssert(nsError.domain == NSURLErrorDomain)
            XCTAssert(nsError.code == NSURLErrorCancelled)
        }
    }

    func testUpload() throws {
        guard let url = Bundle(for: type(of: self)).url(forResource: "cannavaro", withExtension: "jpg") else {
            XCTFail()
            return
        }

        let uploadRequest = BSWFoundation.Request<VoidResponse>(
            endpoint: HTTPBin.API.upload(url)
        )

        let uploadTask = sut.perform(uploadRequest)
        var progress: ProgressObserver! = ProgressObserver.init(progress: uploadTask.progress) { (progress) in
            print(progress.fractionCompleted)
        }
        let _ = try self.waitAndExtractValue(uploadTask, timeout: 10)
        progress = nil
    }

    func testUploadCancel() {
        guard let url = Bundle(for: type(of: self)).url(forResource: "cannavaro", withExtension: "jpg") else {
            XCTFail()
            return
        }

        let uploadRequest = BSWFoundation.Request<VoidResponse>(
            endpoint: HTTPBin.API.upload(url)
        )

        let uploadTask = sut.perform(uploadRequest)
        uploadTask.cancel()

        do {
            let _ = try self.waitAndExtractValue(uploadTask)
            XCTFail("This should fail here")
        } catch let error {
            let nsError = error as NSError
            XCTAssert(nsError.domain == NSURLErrorDomain)
            XCTAssert(nsError.code == NSURLErrorCancelled)
        }
    }
    
    func testUnauthorizedCallsRightMethod() throws {
        let mockDelegate = MockAPIClientDelegate()
        sut = APIClient(environment: HTTPBin.Hosts.production, signature: nil, networkFetcher: Network401Fetcher())
        sut.delegate = mockDelegate
        
        let ipRequest = BSWFoundation.Request<HTTPBin.Responses.IP>(
            endpoint: HTTPBin.API.ip
        )
        // We don't care about the error here
        let _ = try? waitAndExtractValue(sut.perform(ipRequest))
        XCTAssert(mockDelegate.failedURL != nil)
    }
}

import Deferred

private class MockAPIClientDelegate: APIClientDelegate {
    var failedURL: URL?
    func apiClientDidReceiveUnauthorized(forRequest at: URL, apiClient: APIClient) {
        failedURL = at
    }
}

private class Network401Fetcher: APIClientNetworkFetcher {
    
    func fetchData(with urlRequest: URLRequest) -> Task<APIClient.Response> {
        return Task(success: APIClient.Response(data: Data(), httpResponse: HTTPURLResponse(url: URL(string: "apple.com")!, statusCode: 401, httpVersion: nil, headerFields: nil)!))
    }
    
    func uploadFile(with urlRequest: URLRequest, fileURL: URL) -> Task<APIClient.Response> {
        fatalError()
    }
}

struct ValidationError: Swift.Error {}
