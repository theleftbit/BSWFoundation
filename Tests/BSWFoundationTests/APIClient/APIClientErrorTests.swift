import Testing
@testable import BSWFoundation

struct APIClientErrorTests {
    
    @Test
    func errorPrinting_encodingRequestFailed() {
        let localizedDescription = APIClient.Error.encodingRequestFailed.localizedDescription
        #expect(localizedDescription == "The operation couldn’t be completed. (BSWFoundation.APIClient.Error.encodingRequestFailed)")
    }
    
    @Test
    func errorPrinting_serverStatusCode() {
        let errorMessageData =  """
        ["Please try again"]
        """.data(using: .utf8)
        let localizedDescription = APIClient.Error.failureStatusCode(400, errorMessageData).localizedDescription
        #expect(localizedDescription == "The operation couldn’t be completed. (BSWFoundation.APIClient.Error.FailureStatusCode: 400, Message: [\"Please try again\"])")
    }
    
    @Test
    func errorPrinting_serverStatusCode_2() {
        let errorMessageData =  """
        "Please try again"
        """.data(using: .utf8)
        let localizedDescription = APIClient.Error.failureStatusCode(400, errorMessageData).localizedDescription
        #expect(localizedDescription == "The operation couldn’t be completed. (BSWFoundation.APIClient.Error.FailureStatusCode: 400, Message: \"Please try again\")")
    }
}
