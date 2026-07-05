#if canImport(Testing)
import Testing
@testable import BSWFoundation

struct APIClientErrorTests {
    
    @Test
    func errorPrinting_encodingRequestFailed() {
        let localizedDescription = APIClient.Error.encodingRequestFailed.localizedDescription
        #if os(Android) || os(WASI)
        #expect(localizedDescription == "The operation could not be completed. (BSWFoundation.APIClient.Error.encodingRequestFailed)")
        #else
        #expect(localizedDescription == "The operation couldn’t be completed. (BSWFoundation.APIClient.Error.encodingRequestFailed)")
        #endif
    }
    
    @Test
    func errorPrinting_serverStatusCode() {
        let errorMessageData =  """
        ["Please try again"]
        """.data(using: .utf8)
        let localizedDescription = APIClient.Error.failureStatusCode(400, errorMessageData).localizedDescription
        #if os(Android) || os(WASI)
        #expect(localizedDescription == "The operation could not be completed. (BSWFoundation.APIClient.Error.FailureStatusCode: 400, Message: [\"Please try again\"])")
        #else
        #expect(localizedDescription == "The operation couldn’t be completed. (BSWFoundation.APIClient.Error.FailureStatusCode: 400, Message: [\"Please try again\"])")
        #endif
    }
    
    @Test
    func errorPrinting_serverStatusCode_2() {
        let errorMessageData =  """
        "Please try again"
        """.data(using: .utf8)
        let localizedDescription = APIClient.Error.failureStatusCode(400, errorMessageData).localizedDescription
        #if os(Android) || os(WASI)
        #expect(localizedDescription == "The operation could not be completed. (BSWFoundation.APIClient.Error.FailureStatusCode: 400, Message: \"Please try again\")")
        #else
        #expect(localizedDescription == "The operation couldn’t be completed. (BSWFoundation.APIClient.Error.FailureStatusCode: 400, Message: \"Please try again\")")
        #endif
    }
    
    @Test
    func errorPrinting_serverStatusCode_3() {
        let errorMessageData =  """
        {"\(APIClient.Error.ServerMessage)" : "Please try again"}
        """.data(using: .utf8)
        let localizedDescription = APIClient.Error.failureStatusCode(400, errorMessageData).localizedDescription
        #expect(localizedDescription == "Please try again")
    }
}
#endif
