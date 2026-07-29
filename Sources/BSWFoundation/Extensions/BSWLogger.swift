//
//  A small, unified logging facade for BSWFoundation and its consumers.
//

#if canImport(OSLog)
import OSLog
#elseif os(Android)
import AndroidLogging
#elseif os(WASI)
import Logging
#else
#error("BSWLogger is only available on Apple platforms, Android, and WASI")
#endif

/// A lightweight, cross-platform logging facade used throughout BSWFoundation.
///
/// It forwards to the platform's native logging backend, so output lands where you expect:
/// - **Apple** platforms: `OSLog` (the unified logging system / Console.app)
/// - **Android**: `AndroidLogging` (logcat)
/// - **WebAssembly**: `swift-log` (its installed `LogHandler`, e.g. the browser console)
///
/// The API intentionally mirrors `OSLog.Logger` (`init(subsystem:category:)`), so it is a drop-in
/// across the ecosystem and gives every app built on BSWFoundation a single, consistent logger.
public struct BSWLogger: Sendable {

    /// The severity of a log message.
    public enum Level: Sendable {
        case debug, info, warning, error
    }

    private let backing: Logger

    /// Creates a logger for the given subsystem and category.
    public init(subsystem: String, category: String) {
        #if canImport(OSLog) || os(Android)
        self.backing = Logger(subsystem: subsystem, category: category)
        #elseif os(WASI)
        self.backing = Logger(label: "\(subsystem).\(category)")
        #endif
    }

    public func debug(
        _ message: @autoclosure () -> String,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(level: .debug, message(), file: file, function: function, line: line)
    }

    public func info(
        _ message: @autoclosure () -> String,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(level: .info, message(), file: file, function: function, line: line)
    }

    public func warning(
        _ message: @autoclosure () -> String,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(level: .warning, message(), file: file, function: function, line: line)
    }

    public func error(
        _ message: @autoclosure () -> String,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        log(level: .error, message(), file: file, function: function, line: line)
    }

    public func log(
        level: Level,
        _ message: @autoclosure () -> String,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        let text = message()
        #if canImport(OSLog) || os(Android)
        backing.log(level: level.osLogType, "\(formatMessage(text, file: file, function: function, line: line))")
        #elseif os(WASI)
        backing.log(
            level: level.loggingLevel,
            "\(text)",
            file: file,
            function: function,
            line: line
        )
        #endif
    }

    private func formatMessage(_ message: String, file: String, function: String, line: UInt) -> String {
        "[\(file):\(line) \(function)] \(message)"
    }
}

#if canImport(OSLog)
private extension BSWLogger.Level {
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        }
    }
}
#elseif os(Android)
private extension BSWLogger.Level {
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        }
    }
}
#elseif os(WASI)
private extension BSWLogger.Level {
    var loggingLevel: Logging.Logger.Level {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        }
    }
}
#endif
