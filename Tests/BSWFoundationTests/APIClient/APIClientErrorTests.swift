
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
        """.data(using: String.Encoding.utf8)
        let localizedDescription = APIClient.Error.failureStatusCode(400, errorMessageData).localizedDescription
        XCTAssert(localizedDescription == "The operation couldn’t be completed. (BSWFoundation.APIClient.Error.FailureStatusCode: 400, Message: [\"Please try again\"])")
    }
    
    func testErrorPrinting_serverStatusCode_2() {
        let errorMessageData =  """
        "Please try again"
        """.data(using: String.Encoding.utf8)
        let localizedDescription = APIClient.Error.failureStatusCode(400, errorMessageData).localizedDescription
        XCTAssert(localizedDescription == "The operation couldn’t be completed. (BSWFoundation.APIClient.Error.FailureStatusCode: 400, Message: \"Please try again\")")
    }
}



#if os(macOS) // Skip transpiled tests only run on macOS targets
import SkipTest

/// This test case will run the transpiled tests for the Skip module.
@available(macOS 13, macCatalyst 16, *)
final class XCSkipTests: XCTestCase, XCGradleHarness {
    public func testSkipModule() async throws {
        
        // Run the transpiled JUnit tests for the current test module.
        // These tests will be executed locally using Robolectric.
        // Connected device or emulator tests can be run by setting the
        // `ANDROID_SERIAL` environment variable to an `adb devices`
        // ID in the scheme's Run settings.
        //
        // Note that it isn't currently possible to filter the tests to run.
        try await runGradleTests()
    }
}
#endif
