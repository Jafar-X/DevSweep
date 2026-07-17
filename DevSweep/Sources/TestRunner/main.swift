import Foundation
import Core
import Services
import Plugins

@main
struct TestRunner {
    static func main() async {
        var failures = 0

        func pass(_ name: String) {
            fputs("  PASS: \(name)\n", stderr)
        }
        func fail(_ name: String, _ detail: String = "") {
            failures += 1
            let suffix = detail.isEmpty ? "" : " — \(detail)"
            fputs("  FAIL: \(name)\(suffix)\n", stderr)
        }

        // --- Plugin Loader ---

        let loader = DefaultPluginLoader()
        if loader.loadAll().isEmpty {
            pass("PluginLoader: loadAll returns empty when nothing registered")
        } else {
            fail("PluginLoader: loadAll returns empty when nothing registered", "got analyzers")
        }

        // --- Scanner ---

        let scanner = DefaultScanner()
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("devsweep-test-empty-\(UUID())")
        do {
            try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
            let items = try await scanner.scan(paths: [tmp])
            try? FileManager.default.removeItem(at: tmp)
            if items.isEmpty {
                pass("Scanner: empty directory returns empty")
            } else {
                fail("Scanner: empty directory returns empty", "got \(items.count) items")
            }
        } catch {
            fail("Scanner: empty directory returns empty", "\(error)")
        }

        // --- Dummy Analyzer ---

        do {
            let analyzer = DummyAnalyzer(logger: Logger(minimumLevel: .debug))
            let result = try await analyzer.scan()
            if result.analyzerId == "dummy", !result.items.isEmpty, result.totalSizeKB == 512.0 {
                pass("DummyAnalyzer: scan returns result with correct id")
            } else {
                fail("DummyAnalyzer: scan returned unexpected result")
            }
        } catch {
            fail("DummyAnalyzer: scan throws", "\(error)")
        }

        // --- Registry ---

        let dummy = DummyAnalyzer(logger: Logger(minimumLevel: .debug))
        AnalyzerRegistry.register(dummy)
        let analyzers = loader.loadAll()
        if !analyzers.isEmpty {
            pass("Registry: loadAll returns registered analyzer")
        } else {
            fail("Registry: loadAll returns registered analyzer", "empty after register")
        }

        // --- Summary ---

        fputs("\n---\n", stderr)
        if failures == 0 {
            fputs("All tests passed.\n", stderr)
        } else {
            fputs("\(failures) test(s) failed.\n", stderr)
            exit(1)
        }
    }
}
