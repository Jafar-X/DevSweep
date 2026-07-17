import Foundation
import Core
import Services
import Plugins

// Boot
AnalyzerRegistry.register(
    DummyAnalyzer(logger: Logger(minimumLevel: .debug))
)

let container = Container.makeDefault()

// Route
let args = CommandLine.arguments.dropFirst()
let command = args.first ?? "scan"

switch command {
case "scan":
    await ScanCommand.run(using: container)
default:
    fputs("Usage: devsweep scan\n", stderr)
    exit(1)
}

// Command
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
