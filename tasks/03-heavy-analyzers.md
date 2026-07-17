# Milestone 3: Heavy Analyzers

**Goal:** Docker, Xcode, Android, and Git analyzers. These are "heavy" because they deal with large, complex ecosystems and often require parsing non-trivial state.

## Tasks

### 3.1 Docker Analyzer
- [ ] Detect Docker install: Docker Desktop, Colima, OrbStack, Rancher Desktop
- [ ] Run `docker system df` for image/container/volume sizes
- [ ] Run `docker image ls --format json` for per-image breakdown
- [ ] Run `docker volume ls --format json` for dangling volumes
- [ ] Run `docker builder prune --all --force` dry-run size estimate (or calculate from buildkit cache)
- [ ] Handle Docker daemon not running (return empty, no error)
- [ ] Handle no Docker installed
- [ ] Tests with mock docker CLI output

### 3.2 Xcode Analyzer
- [ ] Scan `~/Library/Developer/Xcode/DerivedData` — total size, per-project breakdown
- [ ] Scan `~/Library/Developer/Xcode/Archives`
- [ ] Scan `~/Library/Developer/Xcode/iOS DeviceSupport`
- [ ] Scan `~/Library/Developer/CoreSimulator` — devices, runtime images
- [ ] Scan `~/Library/Caches/org.swift.swiftpm`
- [ ] Detect installed Xcode versions via `xcode-select -p` and `/Applications`
- [ ] Return `AnalysisResult` with: derived data size, archive size, simulator count, Xcode versions
- [ ] Tests with fixture directories

### 3.3 Android Analyzer
- [ ] Detect Android SDK location: `$ANDROID_HOME`, `~/Library/Android/sdk`
- [ ] Scan `platforms/`, `build-tools/`, `ndk/`, `system-images/`, `emulator/`
- [ ] Scan `~/.gradle/caches`
- [ ] Detect AVDs in `~/.android/avd`
- [ ] Parse `sdkmanager --list` if available
- [ ] Handle no Android SDK installed
- [ ] Return `AnalysisResult` with: SDK size, NDK versions, emulator images, Gradle cache size
- [ ] Tests with fixture directories

### 3.4 Git Analyzer
- [ ] Scan home directory for git repos (limited depth, skip node_modules/.build etc.)
- [ ] For each repo: `git count-objects -vH`, `git worktree list`
- [ ] Detect LFS usage and check LFS cache size
- [ ] Check orphan branches (refs not on any remote)
- [ ] Scan global git cache/attributes
- [ ] Return `AnalysisResult` with: repo count, total size, LFS size, worktree count
- [ ] Tests with fixture git repos (created in temp dir)

## Acceptance Criteria
```bash
devsweep scan | jq '.results | map(.analyzerId)'
# → ["dummy", "homebrew", "java", "node", "python", "docker", "xcode", "android", "git"]
```

All 4 new test suites pass.

## Estimated: 4 sessions
