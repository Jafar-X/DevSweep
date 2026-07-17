import Foundation
import Core
import Services

public final class PythonAnalyzer: Analyzer, @unchecked Sendable {
    public let id = "python"
    public let name = "Python"
    public let description = "Scans Python installations, virtual environments, and caches."

    private let logger: Logger
    private let scanner: any StorageScanner

    public init(logger: Logger, scanner: any StorageScanner) {
        self.logger = logger
        self.scanner = scanner
    }

    public func scan() async throws -> AnalysisResult {
        let home = FileManager.default.homeDirectoryForCurrentUser
        var items: [StorageItem] = []

        // Version managers
        let versionPaths: [URL] = [
            home.appendingPathComponent(".pyenv/versions"),
            home.appendingPathComponent(".local/share/uv/tools"),
            home.appendingPathComponent(".asdf/installs/python"),
        ]
        for path in versionPaths {
            if let item = await scanner.scanIfExists(path) { items.append(item) }
        }

        // Anaconda/Miniconda
        let condaPaths: [URL] = [
            home.appendingPathComponent("opt/anaconda3"),
            home.appendingPathComponent("opt/miniconda3"),
            home.appendingPathComponent("anaconda3"),
            home.appendingPathComponent("miniconda3"),
            URL(fileURLWithPath: "/opt/anaconda3"),
            URL(fileURLWithPath: "/opt/miniconda3"),
        ]
        for path in condaPaths {
            if let item = await scanner.scanIfExists(path) { items.append(item) }
        }

        // Virtual environments
        for path in [
            home.appendingPathComponent(".venvs"),
            home.appendingPathComponent(".virtualenvs"),
        ] {
            if let item = await scanner.scanIfExists(path) { items.append(item) }
        }

        // Pip cache
        if let item = await scanner.scanIfExists(
            home.appendingPathComponent("Library/Caches/pip")
        ) {
            items.append(item)
        }

        let totalKB = items.reduce(0) { $0 + $1.sizeKB }
        let totalMB = items.reduce(0) { $0 + $1.sizeMB }

        if items.isEmpty {
            logger.info("Python: no installations or caches found")
        } else {
            logger.info("Python: \(items.count) location(s), \(String(format: "%.1f", totalMB)) MB")
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
