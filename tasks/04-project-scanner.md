# Milestone 4: Project Scanner

**Goal:** Scan the filesystem for developer projects, infer their tool dependencies, and connect installed tools to the projects that use them.

This is the "wow" feature — now DevSweep can answer "Does anything use Java 17?"

## Tasks

### 4.1 Project discovery
- [ ] Recursive scan from `~/Developer`, `~/Projects`, `~/Documents` (configurable paths)
- [ ] Detect project roots by manifest files:
  - `package.json` → Node
  - `pom.xml` / `build.gradle` / `build.gradle.kts` → Java/Kotlin
  - `Cargo.toml` → Rust
  - `go.mod` → Go
  - `requirements.txt` / `pyproject.toml` / `setup.py` → Python
  - `Gemfile` → Ruby
  - `Podfile` → CocoaPods/iOS
  - `composer.json` → PHP
  - `*.xcodeproj` / `*.xcworkspace` → Xcode
  - `.sln` / `.csproj` → .NET
- [ ] Skip: `node_modules`, `.build`, `.git`, `vendor`, `DerivedData`, `.cache`
- [ ] Depth limit to prevent scanning the entire disk
- [ ] Tests with fixture directory tree

### 4.2 Dependency parsing
- [ ] For `package.json`: extract `engines.node`, `dependencies`, `devDependencies`
- [ ] For `pom.xml`: extract Java version, key dependencies
- [ ] For `build.gradle`: extract Java version, key dependencies
- [ ] For `Cargo.toml`: extract rust-version
- [ ] For `go.mod`: extract go version
- [ ] For `pyproject.toml`: extract python version constraint
- [ ] Each parser returns `ProjectDependency` structs
- [ ] Graceful handling of malformed files (log warning, skip)

### 4.3 Dependency graph model
- [ ] `struct Project` — name, path, language, dependencies: [ProjectDependency]
- [ ] `struct ProjectDependency` — tool (java/node/python/...), versionConstraint, required
- [ ] `func buildGraph(projects: [Project], tools: [AnalysisResult]) -> DependencyGraph`
- [ ] `DependencyGraph.usedBy(tool: String, version: String) -> [Project]`
- [ ] `DependencyGraph.unused(tools: [AnalysisResult]) -> [String]`
- [ ] Unit tests with known project + tool combinations

### 4.4 Project scanner as an analyzer
- [ ] `ProjectScannerAnalyzer` conforming to `Analyzer`
- [ ] `scan()` discovers projects, parses dependencies, builds graph
- [ ] Returns `AnalysisResult` with: project count, language breakdown, dependency graph serialized

### 4.5 CLI enhancements
- [ ] `devsweep scan` includes project scanner in results
- [ ] `devsweep deps <tool> <version>` — query the dependency graph
  - `devsweep deps java 17` → lists all projects using Java 17
  - `devsweep deps unused` → lists tools with zero project references

## Acceptance Criteria
```bash
devsweep scan   # Includes project scanner results
devsweep deps java 17   # Correctly identifies projects using Java 17
devsweep deps unused    # Lists orphaned tools
```

Dependency graph tests: given 3 mock projects (2 use Node 20, 1 uses Node 18), `unused` correctly identifies Node 16 as orphaned.

## Estimated: 3 sessions
