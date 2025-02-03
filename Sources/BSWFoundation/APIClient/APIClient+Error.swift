import Foundation

public enum APIClientErrorConstants {
    static let BSWCustomMessage = "bsw_error_message"
}

extension APIClient.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .malformedURL:
            return replaceErrorDescription(with: "malformedURL")
        case .malformedResponse:
            return replaceErrorDescription(with: "malformedResponse")
        case .encodingRequestFailed:
            return replaceErrorDescription(with: "encodingRequestFailed")
        case .failureStatusCode(let statusCode, let data):
            if let data, let bswMessage = JSONParser.parseDataAsBSWCustomMessage(data) {
                return bswMessage
            } else if let data, let prettyError = JSONParser.parseDataAsJSONPrettyPrint(data) {
                return replaceErrorDescription(with: "FailureStatusCode: \(statusCode), Message: \(prettyError)")
            } else {
                return replaceErrorDescription(with: "FailureStatusCode: \(statusCode)")
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
