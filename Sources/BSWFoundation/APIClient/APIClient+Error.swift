#if os(Android)
import FoundationEssentials
#endif
import Foundation


extension APIClient.Error: LocalizedError {
    
    /// If a dictionary with this key is present in the
    /// `data` contained  in `.failureStatusCode`,
    /// then that will be the message shown to the user
    public static let ServerMessage = "bsw_server_error_message"

    public var errorDescription: String? {
        switch self {
        case .malformedURL:
            return replaceErrorDescription(with: "malformedURL")
        case .malformedResponse:
            return replaceErrorDescription(with: "malformedResponse")
        case .encodingRequestFailed:
            return replaceErrorDescription(with: "encodingRequestFailed")
        case .failureStatusCode(let statusCode, let data):
            let defaultMessage = replaceErrorDescription(with: "FailureStatusCode: \(statusCode)")
            guard let data else {
                return defaultMessage
            }
            if let bswMessage = JSONParser.parseDataAsBSWServerErrorMessage(data) {
                return bswMessage
            } else if let prettyError = JSONParser.parseDataAsJSONPrettyPrint(data) {
                return replaceErrorDescription(with: "FailureStatusCode: \(statusCode), Message: \(prettyError)")
            } else {
                return defaultMessage
            }
        }
    }
    
    private func replaceErrorDescription(with apiClientError: String) -> String {
        let localizedError = ShimError().localizedDescription
        let pattern = "\\(.*\\)" //everything between ( and )
        return localizedError.replacingOccurrences(
            of: pattern,
            with: "(BSWFoundation.APIClient.Error.\(apiClientError))",
            options: .regularExpression
        )
    }
    
    /// This is here just to get the "The operation couldn’t be completed" message localized
    private struct ShimError: Error {}
}
