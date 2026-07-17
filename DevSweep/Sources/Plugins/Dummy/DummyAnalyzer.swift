import Foundation
import Core
import Services

public final class DummyAnalyzer: Analyzer, @unchecked Sendable {
    public let id = "dummy"
    public let name = "Dummy Analyzer"
    public let description = "Example analyzer that reports on a temp directory."

    private let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }

    public func scan() async throws -> AnalysisResult {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("devsweep-dummy-\(UUID())")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)

        let items: [StorageItem] = [
            StorageItem(
                path: tmpDir.appendingPathComponent("cache").path,
                sizeKB: 512.0,
                sizeMB: 0.5,
                fileCount: 12,
                lastModified: Date(),
                lastAccessed: Date()
            ),
        ]

        try? FileManager.default.removeItem(at: tmpDir)

        return AnalysisResult(
            analyzerId: id,
            analyzerName: name,
            items: items,
            totalSizeKB: 512.0,
            totalSizeMB: 0.5,
            itemCount: items.count,
            errors: []
        )
    }
}
