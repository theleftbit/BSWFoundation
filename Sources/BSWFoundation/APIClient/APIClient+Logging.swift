import Foundation
#if os(Android)
import FoundationNetworking
import AndroidLogging
#else
import OSLog
#endif

//MARK: Logging

extension APIClient {
    
    func logRequest(request: URLRequest) {
        guard loggingConfiguration.requestBehaviour == .all else {
            return
        }
        let logger = Logger(subsystem: submoduleName("APIClient"), category: "APIClient.Request")
        let httpMethod = request.httpMethod ?? "GET"
        let path = request.url?.path ?? ""
        logger.debug("Sending URLRequest → \(httpMethod) \(path)")
        if let data = request.httpBody, let prettyString = String(data: data, encoding: .utf8) {
            logger.debug("Body: \(prettyString)")
        }
    }
    
    func logResponse(_ response: Response) {
        let logger = Logger(subsystem: submoduleName("APIClient"), category: "APIClient.Response")
        let isError = !(200..<300).contains(response.httpResponse.statusCode)
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
        let logType: OSLogType = isError ? .error : .debug
        let path = response.httpResponse.url?.path ?? ""
        logger.log(level: logType, "Receiving Response → Path: \(path) HTTPStatusCode: \(response.httpResponse.statusCode) ")
        if isError, let errorString = String(data: response.data, encoding: .utf8), !errorString.isEmpty {
            logger.log(level: logType, "Error Message: \(errorString)")
        }
    }
    
    func logNetworkError(_ networkError: Swift.Error, forRequest request: URLRequest) {
        guard loggingConfiguration.responseBehaviour != .none else {
            return
        }
        let logger = Logger(subsystem: submoduleName("APIClient"), category: "APIClient.Network")
        let httpMethod = request.httpMethod ?? "GET"
        let path = request.url?.path ?? ""
        logger.error("Error Received for URLRequest → \(httpMethod) \(path). Error: \(networkError)")
    }
}
