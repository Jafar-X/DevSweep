# Milestone 2: Core Analyzers

**Goal:** Four production analyzers that discover real developer tooling, calculate sizes, and return standardized results.

## Common Pattern

Every analyzer follows the same structure:

```
Plugins/
├── Homebrew/
│   ├── HomebrewAnalyzer.swift
│   └── HomebrewAnalyzerTests.swift
├── Java/
│   ├── JavaAnalyzer.swift
│   └── JavaAnalyzerTests.swift
├── Node/
│   ├── NodeAnalyzer.swift
│   └── NodeAnalyzerTests.swift
└── Python/
    ├── PythonAnalyzer.swift
    └── PythonAnalyzerTests.swift
```

## Tasks

### 2.1 Homebrew Analyzer
- [ ] Detect Homebrew installation path (`/opt/homebrew`, `/usr/local`)
- [ ] Run `brew list --formula` and `brew list --cask` (parse stdout)
- [ ] Run `brew info --json=v2` for sizes and versions
- [ ] Run `brew leaves` to identify top-level vs dependency packages
- [ ] Run `brew services list` to flag running services
- [ ] Return `AnalysisResult` with: formulae count, cask count, total size, running services
- [ ] Handle Homebrew not installed (return empty result, no crash)
- [ ] Tests with mock shell command output

### 2.2 Java Analyzer
- [ ] Scan known install paths: `/Library/Java/JavaVirtualMachines`, `~/.sdkman`, `~/.jenv`
- [ ] Detect install method per JDK: Homebrew, SDKMAN, jEnv, Oracle manual
- [ ] Read `java -version` or `release` file for version, architecture
- [ ] Check for running `java` processes via `ps aux` or `proc_listallpids`
- [ ] Return `AnalysisResult` with: versions, install methods, sizes, process count
- [ ] Tests with fixture directories and mocked process list

### 2.3 Node Analyzer
- [ ] Detect version managers: nvm (`~/.nvm`), fnm, Volta, asdf, Homebrew
- [ ] For each manager, list installed Node versions
- [ ] Scan `~/.npm/_cacache`, `~/.pnpm-store`, Yarn cache for sizes
- [ ] Read global package count per version
- [ ] Return `AnalysisResult` with: version count, cache sizes, global package count
- [ ] Tests with fixture directories

### 2.4 Python Analyzer
- [ ] Detect version managers: pyenv, uv, Homebrew, system Python, Anaconda
- [ ] For pyenv: list installed versions, scan each environment's site-packages
- [ ] For uv: detect tool installations, environments
- [ ] Scan pip cache (`~/Library/Caches/pip`)
- [ ] Detect virtual environments (scan common locations: `~/.venvs`, `~/.virtualenvs`, projects)
- [ ] Return `AnalysisResult` with: versions, env count, cache size, total packages
- [ ] Tests with fixture directories

## Acceptance Criteria
```bash
devsweep scan | jq '.results | map(.analyzerId)' 
# → ["dummy", "homebrew", "java", "node", "python"]
```

All 4 analyzer test suites pass. CLI runs on a real Mac with these tools installed.

## Estimated: 3 sessions (1 per analyzer after the first)
