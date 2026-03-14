#if os(Android)
import Foundation

public struct OSLogType: Equatable, Sendable {
    let label: String

    private init(_ label: String) {
        self.label = label
    }

    public static let debug = OSLogType("DEBUG")
    public static let info = OSLogType("INFO")
    public static let error = OSLogType("ERROR")
    public static let fault = OSLogType("FAULT")
}

public struct Logger: Sendable {
    public let subsystem: String
    public let category: String

    public init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
    }

    public func debug(_ message: String) {
        emit(.debug, message)
    }

    public func warning(_ message: String) {
        emit(.error, message)
    }

    public func error(_ message: String) {
        emit(.error, message)
    }

    public func log(level: OSLogType, _ message: String) {
        emit(level, message)
    }

    private func emit(_ level: OSLogType, _ message: String) {
        print("[\(level.label)] \(subsystem)/\(category): \(message)")
    }
}
#endif
