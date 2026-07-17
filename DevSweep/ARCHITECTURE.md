# Architecture

## Modules

```
DevSweepCLI (executable)
  ├── Core       (protocols, models, plugin loader, scanner)
  ├── Services   (logging)
  └── Plugins    (all analyzers: Dummy, Homebrew, Java, Node, Python)
```

## Request flow

```
main.swift
  → Container.makeDefault() wires logger, pluginLoader, scanner
  → Register all analyzers in AnalyzerRegistry
  → PluginLoader.loadAll() reads registry
  → TaskGroup runs all analyzers concurrently
  → JSONEncoder writes ScanOutput to stdout
```

## Key types

| Type | Location | Role |
|---|---|---|
| `Analyzer` (protocol) | Core/Protocols | One method: `scan() -> AnalysisResult` |
| `StorageScanner` (protocol) | Core/Protocols | Walk filesystem: `scan(paths:) -> [StorageItem]` |
| `PluginLoader` (protocol) | Core/Protocols | Discover analyzers: `loadAll() -> [Analyzer]` |
| `StorageItem` (struct) | Core/Models | Path + sizeKB/sizeMB + fileCount + timestamps |
| `AnalysisResult` (struct) | Core/Models | One analyzer's output |
| `ScanOutput` (struct) | Core/Models | Top-level JSON envelope |
| `AnalyzerRegistry` (enum) | Core/PluginLoader | Thread-safe static registry |
| `DefaultScanner` (class) | Core/StorageEngine | Real filesystem walker |
| `DefaultPluginLoader` (class) | Core/PluginLoader | Returns `AnalyzerRegistry.all` |
| `Logger` (class) | Services/Logging | Structured logger → stderr |
| `Container` (class) | DevSweepCLI | DI: logger, pluginLoader, scanner |

## Adding a new analyzer

1. Create `Sources/Plugins/<Name>/<Name>Analyzer.swift`
2. Implement `Analyzer`, take `Logger` and `StorageScanner` as dependencies
3. Call `scanner.scanIfExists(path)` for each known path
4. Register in `main.swift`: `AnalyzerRegistry.register(NameAnalyzer(...))`

## Concurrency

- Analyzers run in parallel via `TaskGroup`
- One analyzer failing does not affect others
- `StorageScanner.walk()` is synchronous (FileManager enumerator is not Sendable)
- `AnalyzerRegistry` is protected by `NSLock`
- `Logger` writes to `stderr` via `fputs` (thread-safe by POSIX)
