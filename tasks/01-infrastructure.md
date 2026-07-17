# Milestone 1: Infrastructure

**Goal:** A command-line tool that discovers and runs analyzers, scans the filesystem, and outputs JSON. No UI. No real analyzer logic — just one dummy analyzer to prove the pipeline works.

## Folder Structure

```
DevSweep/
├── App/                    # CLI entry point (SwiftPM executable target)
├── Core/
│   ├── Protocols/          # Analyzer, Scanner, PluginLoader
│   ├── Models/             # StorageItem, AnalysisResult, Recommendation
│   ├── PluginLoader/       # Discover & register analyzers at runtime
│   └── StorageEngine/      # Fast filesystem scanning
├── Plugins/
│   └── Dummy/              # Example analyzer (returns hardcoded data)
├── Services/
│   └── Logging/            # Structured logger
└── Tests/
    ├── CoreTests/
    └── PluginTests/
```

## Tasks

### 1.1 Swift Package Manager project
- [ ] `swift package init` with executable target named `devsweep`
- [ ] Set Swift 6 language mode in Package.swift
- [ ] macOS 14 min deployment target
- [ ] Create all empty directories listed above

### 1.2 Core protocols
- [ ] `protocol Analyzer` — `id`, `name`, `description`, `func scan() async throws -> AnalysisResult`
- [ ] `protocol Scanner` — `func scan(paths: [URL]) async throws -> [StorageItem]`
- [ ] `protocol PluginLoader` — `func loadAll() -> [any Analyzer]`

### 1.3 Data models (value types, Codable)
- [ ] `StorageItem` — path, sizeKB, sizeMB, fileCount, lastModified, lastAccessed
  - `sizeKB: Double` — more precise for small items (e.g., `2.5` KB)
  - `sizeMB: Double` — human-readable for larger items (e.g., `1420.3` MB)
  - Both are computed from raw bytes and stored together; consumers pick whichever fits the UI
- [ ] `AnalysisResult` — analyzerId, items: [StorageItem], totalSizeKB, totalSizeMB, errors: [String]
- [ ] Empty `Recommendation` and `Risk` stubs (filled in milestone 5)

### 1.4 Plugin loader
- [ ] Discover types conforming to `Analyzer` at runtime (no hardcoded list)
- [ ] Instantiate and return all analyzers found
- [ ] Unit test: loader discovers the DummyAnalyzer

### 1.5 Storage engine
- [ ] Walk directory tree, collect file sizes and metadata
- [ ] Use `FileManager` with async I/O
- [ ] Skip files the process doesn't have permission to read; log and continue
- [ ] Unit test: scan a temp directory with known contents

### 1.6 Dummy analyzer
- [ ] `DummyAnalyzer` conforming to `Analyzer`
- [ ] `scan()` returns hardcoded results from a known `/tmp` path
- [ ] Tests verify the analyzer → result pipeline

### 1.7 CLI entry point
- [ ] `devsweep scan` loads all analyzers, runs them concurrently via `TaskGroup`
- [ ] Collects results, prints as formatted JSON to stdout
- [ ] Errors per-analyzer are captured, not fatal
- [ ] Smoke test: `devsweep scan` exits 0 and prints valid JSON

### 1.8 Logging service
- [ ] Structured logger with levels (debug, info, warn, error)
- [ ] Output to stderr so stdout stays clean JSON
- [ ] Every analyzer gets a logger instance

## Acceptance Criteria
```bash
devsweep scan | jq .   # Valid JSON
devsweep scan 2>/dev/null | jq '.results | length'  # >= 1 (dummy analyzer)
```

## Estimated: 1 session
