# Milestone 1 — Architecture Design

> **Note:** The implementation deviated from this design in a few places.
> See [ARCHITECTURE.md](../DevSweep/ARCHITECTURE.md) for the current state:
> - `Scanner` renamed to `StorageScanner` (avoided Foundation's `NSScanner` clash)
> - `Container` lives in DevSweepCLI, not Core/DI (Core can't import Services)
> - `Logger.minimumLevel` is `let` not `var` (Swift 6 requires `Sendable` immutability)
> - Tests use a custom runner at `Sources/TestRunner/` (no XCTest in CLT SDK)
> - Added `scanIfExists()` convenience on `StorageScanner`
> - Plugins directory now includes: Homebrew, Java, Node, Python (M2)

## SPM Module Graph

```
DevSweepCLI (executable)
  ├── Core    (library)
  ├── Services (library → Core)
  └── Plugins  (library → Core, Services)
```

4 targets, 3 dependencies. `Core` depends on nothing but Foundation.

## Package.swift

```swift
// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "DevSweep",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "devsweep", targets: ["DevSweepCLI"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "Core"),
        .target(name: "Services", dependencies: ["Core"]),
        .target(name: "Plugins", dependencies: ["Core", "Services"]),
        .executableTarget(
            name: "DevSweepCLI",
            dependencies: ["Core", "Services", "Plugins"]
        ),
        .testTarget(name: "CoreTests", dependencies: ["Core"]),
        .testTarget(name: "PluginTests", dependencies: ["Plugins", "Core"]),
    ]
)
```

## On-Disk Layout

```
DevSweep/
├── Package.swift
├── Sources/
│   ├── DevSweepCLI/
│   │   └── main.swift
│   ├── Core/
│   │   ├── Protocols/
│   │   │   ├── Analyzer.swift
│   │   │   ├── Scanner.swift
│   │   │   └── PluginLoader.swift
│   │   ├── Models/
│   │   │   ├── StorageItem.swift
│   │   │   ├── AnalysisResult.swift
│   │   │   ├── ScanOutput.swift
│   │   │   ├── Recommendation.swift
│   │   │   └── Risk.swift
│   │   ├── PluginLoader/
│   │   │   ├── DefaultPluginLoader.swift
│   │   │   └── AnalyzerRegistry.swift
│   │   ├── StorageEngine/
│   │   │   └── DefaultScanner.swift
│   │   └── DI/
│   │       └── Container.swift
│   ├── Plugins/
│   │   └── Dummy/
│   │       └── DummyAnalyzer.swift
│   └── Services/
│       └── Logging/
│           └── Logger.swift
└── Tests/
    ├── CoreTests/
    │   ├── PluginLoaderTests/
    │   │   └── DefaultPluginLoaderTests.swift
    │   └── StorageEngineTests/
    │       └── DefaultScannerTests.swift
    └── PluginTests/
        └── Dummy/
            └── DummyAnalyzerTests.swift
```

## Protocols

### Sources/Core/Protocols/Analyzer.swift

```swift
import Foundation

/// A plugin that can scan a specific developer ecosystem (Homebrew, Node, etc.)
/// and return standardized results.
public protocol Analyzer: AnyObject, Sendable {
    /// Unique identifier, e.g. "homebrew", "java", "node".
    var id: String { get }

    /// Human-readable label shown in the UI.
    var name: String { get }

    /// One-line summary of what this analyzer covers.
    var description: String { get }

    /// Execute the scan. Called on a background Task.
    /// Must be safe to call concurrently with other analyzers.
    func scan() async throws -> AnalysisResult
}
```

### Sources/Core/Protocols/Scanner.swift

```swift
import Foundation

/// Low-level filesystem walker. Given a list of directories,
/// returns metadata for every file and directory found.
public protocol Scanner: Sendable {
    func scan(paths: [URL]) async throws -> [StorageItem]
}
```

### Sources/Core/Protocols/PluginLoader.swift

```swift
/// Discovers and instantiates all registered Analyzer types.
public protocol PluginLoader: Sendable {
    func loadAll() -> [any Analyzer]
}
```

## Models

### Sources/Core/Models/StorageItem.swift

```swift
import Foundation

/// A single filesystem entry — file or directory — with size metadata.
public struct StorageItem: Codable, Sendable, Identifiable {
    public var id: String { path }

    public let path: String
    public let sizeKB: Double
    public let sizeMB: Double
    public let fileCount: Int
    public let lastModified: Date
    public let lastAccessed: Date

    public init(
        path: String,
        sizeKB: Double,
        sizeMB: Double,
        fileCount: Int,
        lastModified: Date,
        lastAccessed: Date
    ) {
        self.path = path
        self.sizeKB = sizeKB
        self.sizeMB = sizeMB
        self.fileCount = fileCount
        self.lastModified = lastModified
        self.lastAccessed = lastAccessed
    }
}
```

### Sources/Core/Models/AnalysisResult.swift

```swift
import Foundation

/// What one analyzer produced after a scan.
public struct AnalysisResult: Codable, Sendable {
    public let analyzerId: String
    public let analyzerName: String
    public let items: [StorageItem]
    public let totalSizeKB: Double
    public let totalSizeMB: Double
    public let itemCount: Int
    public let errors: [String]

    public init(
        analyzerId: String,
        analyzerName: String,
        items: [StorageItem],
        totalSizeKB: Double,
        totalSizeMB: Double,
        itemCount: Int,
        errors: [String]
    ) {
        self.analyzerId = analyzerId
        self.analyzerName = analyzerName
        self.items = items
        self.totalSizeKB = totalSizeKB
        self.totalSizeMB = totalSizeMB
        self.itemCount = itemCount
        self.errors = errors
    }
}
```

### Sources/Core/Models/ScanOutput.swift

```swift
import Foundation

/// Top-level envelope printed to stdout by the CLI.
public struct ScanOutput: Codable, Sendable {
    public let version: Int
    public let timestamp: Date
    public let durationMs: Int
    public let results: [AnalysisResult]

    public init(version: Int, timestamp: Date, durationMs: Int, results: [AnalysisResult]) {
        self.version = version
        self.timestamp = timestamp
        self.durationMs = durationMs
        self.results = results
    }
}
```

### Sources/Core/Models/Recommendation.swift

```swift
/// Stub — filled in Milestone 5.
public struct Recommendation: Codable, Sendable {}
```

### Sources/Core/Models/Risk.swift

```swift
/// Stub — filled in Milestone 5.
public struct Risk: Codable, Sendable {}
```

## Plugin Loader

### Sources/Core/PluginLoader/AnalyzerRegistry.swift

```swift
/// Each plugin module calls `register()` at startup so the loader
/// can discover it without hardcoding a list of concrete types.
public enum AnalyzerRegistry: Sendable {
    private static let lock = NSLock()
    private static var _analyzers: [any Analyzer] = []

    public static func register(_ analyzer: any Analyzer) {
        lock.lock()
        _analyzers.append(analyzer)
        lock.unlock()
    }

    public static var all: [any Analyzer] {
        lock.lock()
        defer { lock.unlock() }
        return _analyzers
    }
}
```

### Sources/Core/PluginLoader/DefaultPluginLoader.swift

```swift
public final class DefaultPluginLoader: PluginLoader, Sendable {
    public init() {}

    public func loadAll() -> [any Analyzer] {
        AnalyzerRegistry.all
    }
}
```

## Storage Engine

### Sources/Core/StorageEngine/DefaultScanner.swift

```swift
import Foundation

public final class DefaultScanner: Scanner, Sendable {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func scan(paths: [URL]) async throws -> [StorageItem] {
        preconditionFailure("not implemented — stubbed for architecture review")
    }
}
```

## DI Container

### Sources/Core/DI/Container.swift

```swift
import Foundation

/// Simple typed container. No fancy resolver — just explicit properties.
/// Assembled in main.swift at startup.
public final class Container: Sendable {
    public let logger: Logger
    public let pluginLoader: any PluginLoader
    public let scanner: any Scanner

    public init(
        logger: Logger,
        pluginLoader: any PluginLoader,
        scanner: any Scanner
    ) {
        self.logger = logger
        self.pluginLoader = pluginLoader
        self.scanner = scanner
    }

    /// Convenience that wires up all defaults.
    public static func makeDefault() -> Container {
        let logger = Logger()
        let pluginLoader = DefaultPluginLoader()
        let scanner = DefaultScanner()
        return Container(
            logger: logger,
            pluginLoader: pluginLoader,
            scanner: scanner
        )
    }
}
```

## Logger

### Sources/Services/Logging/Logger.swift

```swift
import Foundation

public enum LogLevel: Int, Comparable, Sendable {
    case debug = 0
    case info  = 1
    case warn  = 2
    case error = 3

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public final class Logger: Sendable {
    public var minimumLevel: LogLevel = .info

    public init(minimumLevel: LogLevel = .info) {
        self.minimumLevel = minimumLevel
    }

    public func debug(_ message: String)   { log(.debug, message) }
    public func info(_ message: String)    { log(.info,  message) }
    public func warn(_ message: String)    { log(.warn,  message) }
    public func error(_ message: String)   { log(.error, message) }

    private func log(_ level: LogLevel, _ message: String) {
        guard level >= minimumLevel else { return }
        let line = "[\(level)] \(message)"
        // stderr so stdout stays clean JSON
        fputs(line + "\n", stderr)
    }
}
```

## Dummy Analyzer

### Sources/Plugins/Dummy/DummyAnalyzer.swift

```swift
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
        preconditionFailure("not implemented — stubbed for architecture review")
    }
}
```

Note: `@unchecked Sendable` is used because `Logger` is a reference type but is internally thread-safe (NSLock-free, uses atomic file writes). This will be cleaned up once implementation details are known.

## CLI Entry Point

### Sources/DevSweepCLI/main.swift

```swift
import Foundation
import Core
import Services
import Plugins

// Boot ———————————————

AnalyzerRegistry.register(
    DummyAnalyzer(logger: Logger(minimumLevel: .debug))
)

let container = Container.makeDefault()

// Route ———————————————

let args = CommandLine.arguments.dropFirst()
let command = args.first ?? "scan"

switch command {
case "scan":
    await ScanCommand.run(using: container)
default:
    fputs("Usage: devsweep scan\n", stderr)
    exit(1)
}

// Command —————————————

enum ScanCommand {
    static func run(using container: Container) async {
        let start = Date()
        let analyzers = container.pluginLoader.loadAll()
        container.logger.info("Loaded \(analyzers.count) analyzer(s)")

        var results: [AnalysisResult] = []
        var errors: [String] = []

        await withTaskGroup(of: (String, Result<AnalysisResult, Swift.Error>).self) { group in
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
                case .failure(let e): errors.append(e.localizedDescription)
                }
            }
        }

        let elapsed = Int(Date().timeIntervalSince(start) * 1000)

        if !errors.isEmpty {
            container.logger.warn("\(errors.count) analyzer(s) failed: \(errors.joined(separator: "; "))")
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
```

## Test Sketches

### Tests/CoreTests/PluginLoaderTests/DefaultPluginLoaderTests.swift

```swift
import XCTest
@testable import Core

final class DefaultPluginLoaderTests: XCTestCase {
    func testLoadAll_returnsRegisteredAnalyzers() {
        // Register a dummy analyzer, assert loadAll() sees it
    }

    func testLoadAll_returnsEmptyWhenNothingRegistered() {
        // Clear registry, assert empty
    }
}
```

### Tests/CoreTests/StorageEngineTests/DefaultScannerTests.swift

```swift
import XCTest
@testable import Core

final class DefaultScannerTests: XCTestCase {
    func testScan_knownDirectory_returnsCorrectItems() {
        // Create temp dir with known files, verify StorageItem counts/sizes
    }

    func testScan_emptyDirectory_returnsEmpty() {
        // Scan an empty directory
    }

    func testScan_permissionDenied_skipsAndContinues() {
        // Create unreadable directory, assert no crash
    }
}
```

### Tests/PluginTests/Dummy/DummyAnalyzerTests.swift

```swift
import XCTest
@testable import Plugins
import Core

final class DummyAnalyzerTests: XCTestCase {
    func testScan_returnsAnalysisResult() async throws {
        // Call scan(), verify result has correct analyzerId and non-empty items
    }
}
```

## Concurrency Architecture

```
main.swift
  │ await ScanCommand.run()
  │
  └─ withTaskGroup ──────────────────────────────────────┐
       │                                                  │
       ├─ Task: dummy.scan()     ──→ AnalysisResult ─────┤
       ├─ Task: homebrew.scan()  ──→ AnalysisResult ─────┤  (milestone 2+)
       ├─ Task: java.scan()      ──→ AnalysisResult ─────┤
       └─ Task: node.scan()      ──→ AnalysisResult ─────┤
                                                          │
       All analyzers run concurrently.                    │
       Results collected in insertion order.              │
       One analyzer failing does not affect others.       │
```

## Key Design Decisions

### Why a static registry instead of ObjC runtime discovery?

Swift has no built-in protocol-conformance discovery across modules. `objc_getClassList` requires `@objc` and subclassing `NSObject`, which is not idiomatic Swift 6. The registry pattern is explicit, testable, and trivially understandable. Adding a new analyzer means:
1. Create the module
2. Call `AnalyzerRegistry.register(MyAnalyzer())` in `main.swift`

Two lines, no magic.

### Why a flat Container instead of `@Environment` or Resolver?

This is a CLI, not a SwiftUI app. There is no `@Environment`. A simple struct with typed properties gives compile-time safety and zero overhead. If it ever gets unwieldy, it can be split by concern — but that's a problem for 20+ dependencies, not 3.

### Why is Logger an actor-less reference type?

It writes to stderr via `fputs` — a POSIX function that is inherently thread-safe (it takes a file handle, not shared state). Internal state (`minimumLevel`) is a simple value type property set once at startup. A full actor would add async overhead to every log call with no safety benefit.

## What Milestone 1 Does NOT Do

- No Homebrew/Java/Node/etc. analyzers
- No real StorageEngine implementation (just stubs)
- No risk scores or recommendations
- No SwiftUI
- No persistent config or file I/O beyond the scan
