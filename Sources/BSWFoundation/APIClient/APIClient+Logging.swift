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
        let logger = Logger(subsystem: submoduleName("APIClient"), category: "APIClient.Request")
        switch loggingConfiguration.requestBehaviour {
        case .all:
            let httpMethod = request.httpMethod ?? "GET"
            let path = request.url?.path ?? ""
            logger.debug("Method: \(httpMethod) Path: \(path)")
            if let data = request.httpBody, let prettyString = String(data: data, encoding: .utf8) {
                logger.debug("Body: \(prettyString)")
            }
        default:
            break
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
        logger.log(level: logType, "StatusCode: \(response.httpResponse.statusCode) Path: \(path)")
        if isError, let errorString = String(data: response.data, encoding: .utf8) {
            logger.log(level: logType, "Error Message: \(errorString)")
        }
    }
}
