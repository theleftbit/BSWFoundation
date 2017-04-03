//
//  Created by Pierluigi Cifani on 09/02/2017.
//

import XCTest
import Alamofire
@testable import BSWFoundation


/// Full-suite tests are courtesy of our good friends of HTTPBin

private struct HTTPBIN: Environment {
    fileprivate var basePath: String {
        return "https://httpbin.org/"
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

    func testGET() {
        get(shouldCancel: false)
    }

    func testGETCancel() {
        get(shouldCancel: true)
    }

    func testUpload() {
        upload(shouldCancel: false)
    }

    func testUploadCancel() {
        upload(shouldCancel: true)
    }

    // MARK: - Private

    private func get(shouldCancel: Bool) {
        let exp = expectation(description: "ip")
        let getTask = sut.performAndValidateRequest(forEndpoint: HTTPBINAPI.ip)
        getTask.upon(.main) { result in
            guard shouldCancel else {
                exp.fulfill()
                return
            }

            if let nsError = result.error as NSError?, nsError.domain == NSURLErrorDomain, nsError.code == -999 {
                exp.fulfill()
            } else {
                XCTFail()
            }
        }
        if shouldCancel {
            getTask.cancel()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    private func upload(shouldCancel: Bool) {
        guard let url = Bundle(for: type(of: self)).url(forResource: "cannavaro", withExtension: "jpg") else {
            XCTFail()
            return
        }

        let exp = expectation(description: "uploadTask")
        let uploadTask = sut.performMultipartUpload(
            forEndpoint: HTTPBINAPI.upload,
            multipartParams: [
                MultipartParameter(parameterKey:"key", parameterValue: .url(url)),
                ]
        )

        uploadTask.upon(.main) { result in
            guard shouldCancel else {
                exp.fulfill()
                return
            }

            if let nsError = result.error as NSError?, nsError.domain == NSURLErrorDomain, nsError.code == -999 {
                exp.fulfill()
            } else {
                XCTFail()
            }
        }

        if shouldCancel {
            uploadTask.cancel()
        }

        waitForExpectations(timeout: 600, handler: nil)
    }
}
