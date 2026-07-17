import Foundation

public enum AnalyzerRegistry: @unchecked Sendable {
    private static let lock = NSLock()
    private nonisolated(unsafe) static var _analyzers: [any Analyzer] = []

    public static func register(_ analyzer: any Analyzer) {
        lock.withLock { _analyzers.append(analyzer) }
    }

    public static var all: [any Analyzer] {
        lock.withLock { _analyzers }
    }
}
