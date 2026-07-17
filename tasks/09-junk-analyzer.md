# Milestone 9: Junk Analyzer

**Goal:** Add a `JunkAnalyzer` that detects disposable files — caches, logs, temp files, and Trash. These are the safest things to delete, always rating 95%+ confidence.

Unlike other analyzers that understand specific ecosystems, the Junk analyzer is purely path-based: it knows where apps dump their cache/log junk and reports it.

## What counts as junk

| Category | Paths | Confidence |
|---|---|---|
| App caches | `~/Library/Caches/*` | 98% — apps recreate on next launch |
| Developer caches | `~/Library/Caches/Homebrew`, `~/Library/Caches/Yarn`, `~/Library/Caches/pip`, `~/.gradle/caches`, `~/.npm/_cacache` | 95% — already covered by other analyzers, skip duplicates |
| Logs | `~/Library/Logs/*` | 90% — useful for debugging but generally safe |
| iOS backups | `~/Library/Application Support/MobileSync/Backup/*` | 85% — large, often stale, but could be important |
| User Trash | `~/.Trash/*` | 100% — user explicitly deleted this already |
| Downloads | `~/Downloads/*.dmg`, `~/Downloads/*.pkg` | 70% — user data, show separately with lower confidence |
| Temp files | `/tmp/*`, `$TMPDIR/*` | 98% — macOS cleans on reboot anyway |

## Tasks

### 9.1 JunkAnalyzer

- [ ] Implements `Analyzer` protocol
- [ ] Scans known junk paths using the existing `StorageScanner.scanIfExists()`
- [ ] Returns `AnalysisResult` with items grouped by category
- [ ] Each item tagged with a "category" in the path: `junk://caches/Homebrew`, `junk://logs/Adobe`
- [ ] Skips paths already covered by other analyzers (no double-counting)

### 9.2 Deduplication with existing analyzers

- [ ] `~/.npm/_cacache` → already in NodeAnalyzer. Skip.
- [ ] `~/Library/Caches/pip` → already in PythonAnalyzer. Skip.
- [ ] `~/Library/Developer/Xcode/DerivedData` → already in XcodeAnalyzer. Skip.
- [ ] `~/.gradle/caches` → already in JavaAnalyzer. Skip.
- [ ] Dedup list is hardcoded in JunkAnalyzer for now; analyzers don't need changes.

### 9.3 Categories for risk scoring

The JunkAnalyzer returns items with paths like `junk://category/actual-path`. The risk engine's factors handle these:

- `CacheTypeFactor` already recognizes cache paths → rates them safe
- `SystemComponentFactor` correctly ignores these (not system paths)
- New items get default high confidence (90-98%)

### 9.4 Cleanup: trash-only

- [ ] JunkAnalyzer implements `canCleanup()` → true
- [ ] JunkAnalyzer implements `cleanup()` → `FileManager.trashItem()`
- [ ] No tool-specific commands needed — junk is always file-based
- [ ] Reinstall recipe: "Apps will regenerate this on next launch"

### 9.5 Registration

- [ ] Register `JunkAnalyzer` in both `main.swift` and `AppViewModel`
- [ ] Appears in sidebar as "Junk" with a trash icon

## Acceptance Criteria

- `devsweep scan` includes a "junk" analyzer with items like `junk://caches/...`
- Dashboard shows Junk as a category with recoverable space
- Junk items always show 90%+ confidence
- No overlap: total reported by Junk + other analyzers = true total (no double-counting)
- `devsweep cleanup` on junk items moves them to Trash

## Estimated: 1 session
