import Foundation
import HTTPTypes

//MARK: Logging

extension APIClient {

    func logRequest(_ request: OutboundRequest) {
        guard loggingConfiguration.requestBehaviour == .all else {
            return
        }
        let logger = BSWLogger(subsystem: submoduleName("APIClient"), category: "APIClient.Request")
        let httpMethod = request.httpRequest.method.rawValue
        let path = request.httpRequest.path ?? ""
        logger.debug("Sending Request → \(httpMethod) \(path)")
        if let data = request.body, let prettyString = String(data: data, encoding: .utf8) {
            logger.debug("Body: \(prettyString)")
        }
    }

    func logResponse(_ response: Response, forPath path: String) {
        let logger = BSWLogger(subsystem: submoduleName("APIClient"), category: "APIClient.Response")
        let statusCode = response.statusCode
        let isError = !(200..<300).contains(statusCode)
        let shouldLogThis: Bool = {
            switch loggingConfiguration.responseBehaviour {
            case .all:
                return true
            case .none:
                return false
            case .onlyFailing:
                return isError
            }
        }()
        guard shouldLogThis else { return }
        let logType: BSWLogger.Level = isError ? .error : .debug
        logger.log(level: logType, "Receiving Response → Path: \(path) HTTPStatusCode: \(statusCode) ")
        if isError, let errorString = String(data: response.data, encoding: .utf8), !errorString.isEmpty {
            logger.log(level: logType, "Error Message: \(errorString)")
        }
    }

    func logNetworkError(_ networkError: Swift.Error, forRequest request: OutboundRequest) {
        guard loggingConfiguration.responseBehaviour != .none else {
            return
        }
        let logger = BSWLogger(subsystem: submoduleName("APIClient"), category: "APIClient.Network")
        let httpMethod = request.httpRequest.method.rawValue
        let path = request.httpRequest.path ?? ""
        logger.error("Error Received for Request → \(httpMethod) \(path). Error: \(networkError)")
    }
}
