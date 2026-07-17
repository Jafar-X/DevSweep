import Foundation

public enum LogLevel: Int, Comparable, Sendable {
    case debug = 0
    case info  = 1
    case warn  = 2
    case error = 3

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public final class Logger: Sendable {
    public let minimumLevel: LogLevel

    public init(minimumLevel: LogLevel = .info) {
        self.minimumLevel = minimumLevel
    }

    public func debug(_ message: String) { log(.debug, message) }
    public func info(_ message: String)  { log(.info,  message) }
    public func warn(_ message: String)  { log(.warn,  message) }
    public func error(_ message: String) { log(.error, message) }

    private func log(_ level: LogLevel, _ message: String) {
        guard level >= minimumLevel else { return }
        let line = "[\(level)] \(message)"
        fputs(line + "\n", stderr)
    }
}
