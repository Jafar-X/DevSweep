import Foundation
import Core
import Services

public final class ProjectScannerAnalyzer: Analyzer, @unchecked Sendable {
    public let id = "projects"
    public let name = "Projects"
    public let description = "Discovers developer projects and maps their tool dependencies."

    private let logger: Logger
    private let scanner: any StorageScanner
    private let discovery: ProjectDiscovery
    private let parserRegistry: ManifestParserRegistry

    public init(
        logger: Logger,
        scanner: any StorageScanner,
        discovery: ProjectDiscovery,
        parserRegistry: ManifestParserRegistry
    ) {
        self.logger = logger
        self.scanner = scanner
        self.discovery = discovery
        self.parserRegistry = parserRegistry
    }

    public func scan() async throws -> AnalysisResult {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let roots: [URL] = [
            home.appendingPathComponent("Developer"),
            home.appendingPathComponent("Projects"),
            home.appendingPathComponent("Documents"),
        ]

        let found = discovery.discover(in: roots, maxDepth: 4)
        logger.info("Projects: found \(found.count) manifest(s)")

        var projects: [Project] = []
        for (manifest, _) in found {
            if let project = await parserRegistry.parse(manifest) {
                projects.append(project)
            }
        }

        // Also scan project directories for storage size
        let seenDirs = Set(found.map { $0.root.path })
        var storageItems: [StorageItem] = []
        for dirPath in seenDirs {
            if let item = await scanner.scanIfExists(URL(fileURLWithPath: dirPath)) {
                storageItems.append(item)
            }
        }

        let totalKB = storageItems.reduce(0) { $0 + $1.sizeKB }
        let totalMB = storageItems.reduce(0) { $0 + $1.sizeMB }

        logger.info(
            "Projects: \(projects.count) parsed, " +
            "languages: \(Set(projects.map(\.language)).sorted().joined(separator: ", "))"
        )

        return AnalysisResult(
            analyzerId: id,
            analyzerName: name,
            items: storageItems,
            totalSizeKB: totalKB,
            totalSizeMB: totalMB,
            itemCount: projects.count,
            errors: []
        )
    }

    /// Exposed for the CLI `deps` subcommand.
    public func graph() async -> DependencyGraph {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let roots: [URL] = [
            home.appendingPathComponent("Developer"),
            home.appendingPathComponent("Projects"),
            home.appendingPathComponent("Documents"),
        ]
        let found = discovery.discover(in: roots, maxDepth: 4)
        var projects: [Project] = []
        for (manifest, _) in found {
            if let project = await parserRegistry.parse(manifest) {
                projects.append(project)
            }
        }
        return DependencyGraph(projects: projects)
    }
}
