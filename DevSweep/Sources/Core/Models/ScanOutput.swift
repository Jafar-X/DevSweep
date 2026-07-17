import Foundation

public struct ScanOutput: Codable, Sendable {
    public let version: Int
    public let timestamp: Date
    public let durationMs: Int
    public let results: [AnalysisResult]

    public init(version: Int, timestamp: Date, durationMs: Int, results: [AnalysisResult]) {
        self.version = version
        self.timestamp = timestamp
        self.durationMs = durationMs
        self.results = results
    }
}
