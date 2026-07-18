import SwiftUI
import Core
import Services
import Plugins
import DevSweepKit

@MainActor
@Observable
public final class AppViewModel {
    private let container: Container
    private let projectScanner: ProjectScannerAnalyzer

    var results: [AnalysisResult] = []
    var recommendations: [Recommendation] = []
    var dependencyGraph: DependencyGraph?
    var isScanning = false
    var lastScanDuration: Int = 0
    var lastScanDate: Date?
    var errorMessage: String?

    var totalStorageMB: Double {
        results.reduce(0) { $0 + $1.totalSizeMB }
    }

    var potentiallyRecoverableMB: Double {
        var total = 0.0
        for rec in recommendations {
            if rec.verdict == .safeToRemove || rec.verdict == .considerRemoving {
                for r in results {
                    for item in r.items where item.path == rec.itemPath {
                        total += item.sizeMB
                    }
                }
            }
        }
        return total
    }

    var analyzerCount: Int { results.count }

    public init() {
        let c = Container.makeDefault()
        self.container = c
        self.projectScanner = ProjectScannerAnalyzer(
            logger: c.logger,
            scanner: c.scanner,
            discovery: c.projectDiscovery,
            parserRegistry: c.manifestParser
        )

        // Register all analyzers
        AnalyzerRegistry.register(DummyAnalyzer(logger: c.logger))
        AnalyzerRegistry.register(HomebrewAnalyzer(logger: c.logger, scanner: c.scanner))
        AnalyzerRegistry.register(NodeAnalyzer(logger: c.logger, scanner: c.scanner))
        AnalyzerRegistry.register(JavaAnalyzer(logger: c.logger, scanner: c.scanner))
        AnalyzerRegistry.register(PythonAnalyzer(logger: c.logger, scanner: c.scanner))
        AnalyzerRegistry.register(DockerAnalyzer(logger: c.logger, scanner: c.scanner))
        AnalyzerRegistry.register(XcodeAnalyzer(logger: c.logger, scanner: c.scanner))
        AnalyzerRegistry.register(AndroidAnalyzer(logger: c.logger, scanner: c.scanner))
        AnalyzerRegistry.register(GitAnalyzer(logger: c.logger, scanner: c.scanner))
        AnalyzerRegistry.register(projectScanner)
    }

    func refresh() async {
        isScanning = true
        errorMessage = nil
        defer { isScanning = false }

        let analyzers = container.pluginLoader.loadAll()
        var collected: [AnalysisResult] = []

        await withTaskGroup(of: (String, Result<AnalysisResult, Error>).self) { group in
            for analyzer in analyzers {
                group.addTask {
                    do {
                        let result = try await analyzer.scan()
                        return (analyzer.id, .success(result))
                    } catch {
                        return (analyzer.id, .failure(error))
                    }
                }
            }
            for await (_, result) in group {
                if case .success(let r) = result { collected.append(r) }
            }
        }

        results = collected
        lastScanDate = Date()

        let graph = await projectScanner.graph()
        dependencyGraph = graph

        let procPaths = container.processScanner.runningProcessPaths()
        let context = RiskContext(dependencyGraph: graph, runningProcessPaths: procPaths)
        recommendations = container.riskEngine.evaluate(results: collected, context: context)
    }

    func results(for analyzerId: String) -> AnalysisResult? {
        results.first { $0.analyzerId == analyzerId }
    }

    /// Joins StorageItems from an analyzer's result with their Recommendations.
    func recommendations(for analyzerId: String) -> [(StorageItem, Recommendation?)] {
        guard let result = results.first(where: { $0.analyzerId == analyzerId }) else {
            return []
        }
        let recByPath = Dictionary(grouping: recommendations, by: \.itemPath)
        return result.items.map { item in
            (item, recByPath[item.path]?.first)
        }
    }
}
