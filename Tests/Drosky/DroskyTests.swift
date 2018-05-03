//
//  Created by Pierluigi Cifani on 09/02/2017.
//

import XCTest
import Alamofire
@testable import BSWFoundation


/// Full-suite tests are courtesy of our good friends of HTTPBin

private struct HTTPBIN: Environment {
    fileprivate var baseURL: URL {
        return URL(string: "https://httpbin.org/")!
    }
}

private enum HTTPBINAPI: Endpoint {
    case ip
    case upload

    var path: String {
        switch self {
        case .upload:
            return "post"
        case .ip:
            return "ip"
        }
    }

    var method: BSWFoundation.HTTPMethod {
        switch self {
        case .upload:
            return .POST
        default:
            return .GET
        }
    }
}

class DroskyTests: XCTestCase {

    var sut: Drosky!

    override func setUp() {
        super.setUp()
        sut = Drosky(environment: HTTPBIN())
    }

    func testGET() throws {
        let getTask = sut.performAndValidateRequest(forEndpoint: HTTPBINAPI.ip)
        let _ = try self.waitAndExtractValue(getTask)
    }

    func testGETCancel() throws {
        let getTask = sut.performAndValidateRequest(forEndpoint: HTTPBINAPI.ip)
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

        let uploadTask = sut.performMultipartUpload(
            forEndpoint: HTTPBINAPI.upload,
            multipartParams: [
                MultipartParameter(parameterKey: "key", parameterValue: .url(url), fileName: "cannavaro.jpg", mimeType: .imageJPEG)
            ]
        )

        let _ = try self.waitAndExtractValue(uploadTask, timeout: 5)
    }

    func testUploadCancel() {
        guard let url = Bundle(for: type(of: self)).url(forResource: "cannavaro", withExtension: "jpg") else {
            XCTFail()
            return
        }

        let uploadTask = sut.performMultipartUpload(
            forEndpoint: HTTPBINAPI.upload,
            multipartParams: [
                MultipartParameter(parameterKey: "key", parameterValue: .url(url), fileName: "cannavaro.jpg", mimeType: .imageJPEG)
            ]
        )
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
}
