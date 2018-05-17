//
//  Created by Pierluigi Cifani on 09/02/2017.
//

import XCTest
import BSWFoundation

class APIClientTests: XCTestCase {

    let sut = APIClient(environment: HTTPBin.Hosts.production)

    func testGET() throws {
        let ipRequest = BSWFoundation.Request<HTTPBin.Responses.IP>(
            endpoint: HTTPBin.API.ip
        )

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
            endpoint: HTTPBin.API.upload
        )

        let uploadTask = sut.performMultipartUpload(uploadRequest, parameters: [
            MultipartParameter(parameterKey: "key", parameterValue: .url(url), fileName: "cannavaro.jpg", mimeType: .imageJPEG)
            ])

        let _ = try self.waitAndExtractValue(uploadTask, timeout: 5)
    }

    func testUploadCancel() {
        guard let url = Bundle(for: type(of: self)).url(forResource: "cannavaro", withExtension: "jpg") else {
            XCTFail()
            return
        }

        let uploadRequest = BSWFoundation.Request<VoidResponse>(
            endpoint: HTTPBin.API.upload
        )

        let uploadTask = sut.performMultipartUpload(uploadRequest, parameters: [
            MultipartParameter(parameterKey: "key", parameterValue: .url(url), fileName: "cannavaro.jpg", mimeType: .imageJPEG)
            ])
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
