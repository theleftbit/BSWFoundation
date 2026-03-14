#if os(Android) && !SKIP
public struct OSLogType: Equatable, Sendable {
    public init() {}

    public static let debug = OSLogType()
    public static let info = OSLogType()
    public static let error = OSLogType()
    public static let fault = OSLogType()
}

public struct Logger: Sendable {
    public init(subsystem: String, category: String) {}

    public func debug(_ message: String) {}
    public func warning(_ message: String) {}
    public func error(_ message: String) {}
    public func log(level: OSLogType, _ message: String) {}
}
#endif
