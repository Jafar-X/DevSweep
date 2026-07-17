# Getting Started

## Requirements

- macOS 14+
- Xcode Command Line Tools (`xcode-select --install`)

## Build

```bash
cd DevSweep
swift build
```

## Run (CLI)

```bash
swift run devsweep scan
swift run devsweep deps                 # project dependency summary
swift run devsweep deps java            # projects using a tool
swift run devsweep deps unused          # tools with no project references
swift run devsweep recommend            # risk-scored recommendations
swift run devsweep explain <path>       # detailed reasoning for a path
```

For clean JSON output (no logs):

```bash
swift run devsweep scan 2>/dev/null | jq .
```

## Run (GUI)

```bash
./build-app.sh
open DevSweep.app
```

## Test

```bash
swift run test-runner
```

Expected output:

```
  PASS: PluginLoader: loadAll returns empty when nothing registered
  PASS: Scanner: empty directory returns empty
  PASS: DummyAnalyzer: scan returns result with correct id
  PASS: Registry: loadAll returns registered analyzer

---
All tests passed.
```
