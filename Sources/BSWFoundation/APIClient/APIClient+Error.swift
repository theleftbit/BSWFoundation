import Foundation

extension APIClient.Error: LocalizedError {
    public var errorDescription: String? {
        let apiClientError: String = {
            switch self {
            case .malformedURL:
                return "malformedURL"
            case .malformedResponse:
                return "malformedResponse"
            case .encodingRequestFailed:
                return "encodingRequestFailed"
            case .failureStatusCode(let statusCode, let data):
                if let data = data, let prettyError = JSONParser.parseDataAsJSONPrettyPrint(data) {
                    return "FailureStatusCode: \(statusCode), Message: \(prettyError)"
                } else {
                    return "FailureStatusCode: \(statusCode)"
                }
            }
        }()
        let localizedError = ShimError().localizedDescription
        let pattern = "\\(.*\\)" //everything between ( and )
        return localizedError.replacingOccurrences(
            of: pattern,
            with: "(BSWFoundation.APIClient.Error.\(apiClientError))",
            options: NSString.CompareOptions.regularExpression
        )
    }
    
    /// This is here just to get the "The operation couldn’t be completed" message localized
    private struct ShimError: Error {}
}
