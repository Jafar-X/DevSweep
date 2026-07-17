import Foundation
import Core
import Services

public final class JavaAnalyzer: Analyzer, @unchecked Sendable {
    public let id = "java"
    public let name = "Java"
    public let description = "Scans installed JDKs from all known managers."

    private let logger: Logger
    private let scanner: any StorageScanner

    public init(logger: Logger, scanner: any StorageScanner) {
        self.logger = logger
        self.scanner = scanner
    }

    public func scan() async throws -> AnalysisResult {
        let home = FileManager.default.homeDirectoryForCurrentUser
        var items: [StorageItem] = []

        // JDK paths
        let jdkPaths: [URL] = [
            URL(fileURLWithPath: "/Library/Java/JavaVirtualMachines"),
            home.appendingPathComponent(".sdkman/candidates/java"),
            home.appendingPathComponent(".jenv/versions"),
            home.appendingPathComponent(".asdf/installs/java"),
        ]
        for path in jdkPaths {
            if let item = await scanner.scanIfExists(path) { items.append(item) }
        }

        // Homebrew JDK prefixes
        for cellar in ["/opt/homebrew/Cellar", "/usr/local/Cellar"] {
            for prefix in ["openjdk", "adoptopenjdk", "temurin", "zulu", "sapmachine"] {
                if let item = await scanner.scanIfExists(
                    URL(fileURLWithPath: cellar).appendingPathComponent(prefix)
                ) {
                    items.append(item)
                }
            }
        }

        // Gradle cache
        if let item = await scanner.scanIfExists(
            home.appendingPathComponent(".gradle/caches")
        ) {
            items.append(item)
        }

        let totalKB = items.reduce(0) { $0 + $1.sizeKB }
        let totalMB = items.reduce(0) { $0 + $1.sizeMB }

        if items.isEmpty {
            logger.info("Java: no JDKs or caches found")
        } else {
            logger.info("Java: \(items.count) location(s), \(String(format: "%.1f", totalMB)) MB")
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
