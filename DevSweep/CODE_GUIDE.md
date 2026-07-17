# Code Guide (for Java developers)

## Swift ↔ Java mapping

| Swift | Java equivalent |
|---|---|
| `protocol` | `interface` |
| `struct` | `record` (value type, stack-allocated) |
| `class` (with `final`) | `final class` |
| `extension` | no equivalent (add methods to existing types) |
| `enum` | `enum` but can hold data like sealed classes |
| `let` | `final var` |
| `var` | regular variable |
| `guard let x = maybeNil else { return }` | `if (x == null) return;` |
| `any Protocol` | interface as type (dynamic dispatch) |
| `some Protocol` | generic bounded type (static dispatch) |
| `async/await` | same as `CompletableFuture` |
| `TaskGroup` | `ExecutorService.invokeAll` |
| `Sendable` | thread-safe marker |

## Where to look

### Entry point — `Sources/DevSweepCLI/main.swift`

Like `public static void main()`. Registers plugins, parses the command (`scan`), loads all analyzers, runs them in parallel via `TaskGroup`, serializes results to JSON and prints to stdout.

### Models — `Sources/Core/Models/`

- **StorageItem.swift** — a `record` with `path`, `sizeKB`, `sizeMB`, `fileCount`, timestamps.
- **AnalysisResult.swift** — what one analyzer returns (items + totals + errors).
- **ScanOutput.swift** — top-level JSON envelope (version, timestamp, duration, results array).
- **Recommendation.swift** / **Risk.swift** — empty stubs filled in Milestone 5.

### Interfaces — `Sources/Core/Protocols/`

- **Analyzer.swift** — one method: `scan() -> AnalysisResult`. Every plugin implements this.
- **Scanner.swift** — walks the filesystem: `scan(paths) -> [StorageItem]`.
- **PluginLoader.swift** — discovers analyzers: `loadAll() -> [Analyzer]`.

### Plugin system — `Sources/Core/PluginLoader/`

- **AnalyzerRegistry.swift** — a static thread-safe registry (`Map<String, Analyzer>` singleton).
- **DefaultPluginLoader.swift** — wraps `Registry.all`.

### DI — `Sources/DevSweepCLI/Container.swift`

Hand-written `ApplicationContext`. Three properties: `logger`, `pluginLoader`, `scanner`. The `makeDefault()` factory wires real implementations.

### First plugin — `Sources/Plugins/Dummy/DummyAnalyzer.swift`

Template for every future analyzer. Implements `Analyzer`, creates a temp directory, reports hardcoded `StorageItem`s.

### Logger — `Sources/Services/Logging/Logger.swift`

Four levels (debug/info/warn/error). Writes to stderr so stdout stays clean JSON.

### Package manifest — `Package.swift`

Like `pom.xml`. Declares 5 modules and their dependency graph:

```
DevSweepCLI (executable)
  ├── Core       (protocols + models + implementations)
  ├── Services   (logging)
  └── Plugins    (analyzers)
```

### Tests — `Sources/TestRunner/main.swift`

Plain `assert()`-based tests. `swift run test-runner` executes them.

## Request flow

```
main.swift
  → Register DummyAnalyzer in Registry
  → Container.makeDefault() wires dependencies
  → PluginLoader.loadAll() reads Registry
  → TaskGroup runs all analyzers concurrently
  → JSONEncoder writes ScanOutput to stdout
```
