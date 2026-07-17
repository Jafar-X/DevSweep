import Foundation
import Core
import Services
import Plugins

// Boot
let container = Container.makeDefault()
let projectScanner = ProjectScannerAnalyzer(
    logger: container.logger,
    scanner: container.scanner,
    discovery: container.projectDiscovery,
    parserRegistry: container.manifestParser
)

AnalyzerRegistry.register(DummyAnalyzer(logger: container.logger))
AnalyzerRegistry.register(HomebrewAnalyzer(logger: container.logger, scanner: container.scanner))
AnalyzerRegistry.register(NodeAnalyzer(logger: container.logger, scanner: container.scanner))
AnalyzerRegistry.register(JavaAnalyzer(logger: container.logger, scanner: container.scanner))
AnalyzerRegistry.register(PythonAnalyzer(logger: container.logger, scanner: container.scanner))
AnalyzerRegistry.register(DockerAnalyzer(logger: container.logger, scanner: container.scanner))
AnalyzerRegistry.register(XcodeAnalyzer(logger: container.logger, scanner: container.scanner))
AnalyzerRegistry.register(AndroidAnalyzer(logger: container.logger, scanner: container.scanner))
AnalyzerRegistry.register(GitAnalyzer(logger: container.logger, scanner: container.scanner))
AnalyzerRegistry.register(projectScanner)

// Route
let args = CommandLine.arguments.dropFirst()
let command = args.first ?? "scan"
let subArgs = args.dropFirst()

switch command {
case "scan":
    await ScanCommand.run(using: container)
case "deps":
    await DepsCommand.run(projectScanner: projectScanner, args: Array(subArgs))
default:
    fputs("Usage: devsweep {scan | deps [tool] | deps unused}\n", stderr)
    exit(1)
}

// MARK: - Commands

enum ScanCommand {
    static func run(using container: Container) async {
        let start = Date()
        let analyzers = container.pluginLoader.loadAll()
        container.logger.info("Loaded \(analyzers.count) analyzer(s)")

        var results: [AnalysisResult] = []
        var errorMessages: [String] = []

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
                switch result {
                case .success(let r): results.append(r)
                case .failure(let e): errorMessages.append(e.localizedDescription)
                }
            }
        }

        let elapsed = Int(Date().timeIntervalSince(start) * 1000)

        if !errorMessages.isEmpty {
            container.logger.warn(
                "\(errorMessages.count) analyzer(s) failed: \(errorMessages.joined(separator: "; "))"
            )
        }

        let output = ScanOutput(
            version: 1,
            timestamp: Date(),
            durationMs: elapsed,
            results: results
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let json = try? encoder.encode(output) else {
            fputs("Error: failed to encode output\n", stderr)
            exit(2)
        }

        fputs(String(data: json, encoding: .utf8)!, stdout)
    }
}

enum DepsCommand {
    static func run(projectScanner: ProjectScannerAnalyzer, args: [String]) async {
        let graph = await projectScanner.graph()
        let sub = args.first ?? ""

        if sub == "unused" {
            // Known tool IDs from registered analyzers
            let knownTools: Set<String> = [
                "homebrew", "java", "node", "python",
                "docker", "xcode", "android", "git",
            ]
            let unused = graph.unusedTools(knownToolIds: knownTools)
            if unused.isEmpty {
                print("All known tools are referenced by at least one project.")
            } else {
                print("Unreferenced tools: \(unused.sorted().joined(separator: ", "))")
            }
        } else if !sub.isEmpty {
            let projects = graph.projectsUsing(tool: sub)
            if projects.isEmpty {
                print("No projects found using \(sub)")
            } else {
                print("Projects using \(sub) (\(projects.count)):")
                for p in projects {
                    print("  \(p.name) — \(p.path)")
                }
            }
        } else {
            // Summary
            print("Discovered \(graph.projects.count) project(s)")
            let byLang = Dictionary(grouping: graph.projects, by: \.language)
            for (lang, projs) in byLang.sorted(by: { $0.value.count > $1.value.count }) {
                print("  \(lang): \(projs.count)")
            }
        }
    }
}
