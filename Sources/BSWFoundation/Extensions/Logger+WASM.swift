#if os(WASI)
import Logging

/// Minimal `OSLog`-compatible logging shim for WebAssembly, where `OSLog` is unavailable.
/// It keeps the OSLog-shaped call sites (`Logger(subsystem:category:)`, `OSLogType`) compiling
/// unchanged while routing output through swift-log, so a custom `LogHandler` (e.g. one that
/// forwards to `console.debug/warn/error` via JavaScriptKit) can be installed by the host app.
struct Logger {
    private let backing: Logging.Logger

    init(subsystem: String, category: String) {
        self.backing = Logging.Logger(label: "\(subsystem).\(category)")
    }

    func debug(_ message: String) { backing.debug("\(message)") }
    func info(_ message: String) { backing.info("\(message)") }
    func warning(_ message: String) { backing.warning("\(message)") }
    func error(_ message: String) { backing.error("\(message)") }
    func log(level: OSLogType, _ message: String) { backing.log(level: level.swiftLogLevel, "\(message)") }
}

/// `OSLogType` stand-in so the shared logging code compiles on wasm.
enum OSLogType {
    case debug, info, error, `default`

    var swiftLogLevel: Logging.Logger.Level {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .error: return .error
        case .default: return .notice
        }
    }
}
#endif
