# Getting Started

## Requirements

- macOS 14+
- Xcode Command Line Tools (`xcode-select --install`)

## Build

```bash
cd DevSweep
swift build
```

## Run

```bash
swift run devsweep scan
```

For clean JSON output (no logs):

```bash
swift run devsweep scan 2>/dev/null | jq .
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
