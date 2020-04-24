
import XCTest
@testable import BSWFoundation

class APIClientErrorTests: XCTestCase {
    func testErrorPrinting_encodingRequestFailed() {
        let localizedDescription = APIClient.Error.encodingRequestFailed.localizedDescription
        XCTAssert(localizedDescription == "The operation couldn’t be completed. (BSWFoundation.APIClient.Error.encodingRequestFailed)")
    }
    
    func testErrorPrinting_serverStatusCode() {
        let errorMessageData =  """
        ["Please try again"]
        """.data(using: .utf8)
        let localizedDescription = APIClient.Error.failureStatusCode(400, errorMessageData).localizedDescription
        XCTAssert(localizedDescription == "The operation couldn’t be completed. (BSWFoundation.APIClient.Error.FailureStatusCode: 400, Message: [\"Please try again\"])")
    }
    
    func testErrorPrinting_serverStatusCode_2() {
        let errorMessageData =  """
        "Please try again"
        """.data(using: .utf8)
        let localizedDescription = APIClient.Error.failureStatusCode(400, errorMessageData).localizedDescription
        XCTAssert(localizedDescription == "The operation couldn’t be completed. (BSWFoundation.APIClient.Error.FailureStatusCode: 400, Message: \"Please try again\")")
    }
}
