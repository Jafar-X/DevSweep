import Foundation
import Core
import Services

public final class GitAnalyzer: Analyzer, @unchecked Sendable {
    public let id = "git"
    public let name = "Git"
    public let description = "Scans Git repositories, LFS objects, and worktrees."

    private let logger: Logger
    private let scanner: any StorageScanner

    public init(logger: Logger, scanner: any StorageScanner) {
        self.logger = logger
        self.scanner = scanner
    }

    public func scan() async throws -> AnalysisResult {
        let home = FileManager.default.homeDirectoryForCurrentUser
        var items: [StorageItem] = []

        // Scan common project directories for .git repos (depth 3)
        let scanRoots: [URL] = [
            home.appendingPathComponent("Developer"),
            home.appendingPathComponent("Projects"),
        ]

        for root in scanRoots {
            for repoDotGit in findGitRepos(in: root, maxDepth: 3) {
                if let item = await scanner.scanIfExists(repoDotGit) {
                    items.append(item)
                }
            }
        }

        // Git LFS cache
        if let item = await scanner.scanIfExists(
            home.appendingPathComponent(".git-lfs")
        ) { items.append(item) }

        let totalKB = items.reduce(0) { $0 + $1.sizeKB }
        let totalMB = items.reduce(0) { $0 + $1.sizeMB }

        if items.isEmpty {
            logger.info("Git: no repos or LFS caches found")
        } else {
            logger.info("Git: \(items.count) repo(s), \(String(format: "%.1f", totalMB)) MB")
        }

        return AnalysisResult(
            analyzerId: id, analyzerName: name,
            items: items, totalSizeKB: totalKB, totalSizeMB: totalMB,
            itemCount: items.count, errors: []
        )
    }

    /// Uses FileManager.enumerator for a single efficient walk up to maxDepth.
    private func findGitRepos(in root: URL, maxDepth: Int) -> [URL] {
        guard FileManager.default.fileExists(atPath: root.path) else { return [] }

        let skipNames: Set<String> = [
            "node_modules", ".build", "DerivedData", ".cache",
            "vendor", "Pods", ".swiftpm", "__pycache__",
        ]

        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsPackageDescendants]
        ) else { return [] }

        var result: [URL] = []

        for case let url as URL in enumerator {
            let name = url.lastPathComponent
            if skipNames.contains(name) {
                enumerator.skipDescendants()
                continue
            }
            // Skip hidden dirs except .git
            if name.hasPrefix(".") && name != ".git" {
                enumerator.skipDescendants()
                continue
            }

            // Depth check: how many levels below root are we?
            let relative = url.path.replacingOccurrences(of: root.path, with: "")
            let depth = relative.split(separator: "/").count
            if depth > maxDepth {
                enumerator.skipDescendants()
                continue
            }

            // Found a .git directory
            if name == ".git" {
                result.append(url)
                enumerator.skipDescendants()
            }
        }

        return result
    }
}
