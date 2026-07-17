import Foundation
import Core
import Services

public final class NodeAnalyzer: Analyzer, @unchecked Sendable {
    public let id = "node"
    public let name = "Node.js"
    public let description = "Scans Node.js installations, version managers, and caches."

    private let logger: Logger
    private let scanner: any StorageScanner

    public init(logger: Logger, scanner: any StorageScanner) {
        self.logger = logger
        self.scanner = scanner
    }

    public func scan() async throws -> AnalysisResult {
        let home = FileManager.default.homeDirectoryForCurrentUser
        var items: [StorageItem] = []

        let paths: [URL] = [
            home.appendingPathComponent(".nvm/versions/node"),
            home.appendingPathComponent(".volta/tools/image/node"),
            home.appendingPathComponent(".asdf/installs/nodejs"),
            URL(fileURLWithPath: "/opt/homebrew/Cellar"),
            home.appendingPathComponent(".npm/_cacache"),
            home.appendingPathComponent(".pnpm-store"),
            home.appendingPathComponent("Library/Caches/Yarn"),
        ]

        for path in paths {
            if let item = await scanner.scanIfExists(path) {
                items.append(item)
            }
        }

        let totalKB = items.reduce(0) { $0 + $1.sizeKB }
        let totalMB = items.reduce(0) { $0 + $1.sizeMB }

        if items.isEmpty {
            logger.info("Node.js: no installations or caches found")
        } else {
            logger.info("Node.js: \(items.count) location(s), \(String(format: "%.1f", totalMB)) MB")
        }

        return AnalysisResult(
            analyzerId: id,
            analyzerName: name,
            items: items,
            totalSizeKB: totalKB,
            totalSizeMB: totalMB,
            itemCount: items.count,
            errors: []
        )
    }
}
