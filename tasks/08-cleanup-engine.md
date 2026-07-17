# Milestone 8: Cleanup Engine

**Goal:** Add safe deletion capability. Each analyzer knows how to delete its own items correctly (brew uninstall, docker rmi, nvm uninstall, etc.). A CleanupEngine orchestrates this with safety checks. Deletion is trash-based — nothing is permanently destroyed.

**Core rule:** DevSweep never runs `rm -rf` on anything unless there's no analyzer-specific cleaner. Even then, it moves to Trash, not permanent delete.

## Design

### Cleanup protocol

```swift
protocol Analyzer {
    func scan() -> AnalysisResult
    func cleanup(items: [StorageItem], dryRun: Bool) -> [CleanupResult]
}
```

`cleanup` gets a list of StorageItems the user selected. `dryRun: true` means "tell me what WOULD happen" (preview). `dryRun: false` means "do it."

### CleanupResult

```swift
struct CleanupResult {
    let path: String
    let bytesFreed: Int64
    let success: Bool
    let error: String?
    let reinstallCommand: String?       // "brew install openjdk@17"
    let undoDescription: String?        // "Moved to ~/.Trash"
}
```

## Tasks

### 8.1 Extend the Analyzer protocol

- [ ] Add `func canCleanup(item: StorageItem) -> Bool` — does this analyzer know how to delete this?
- [ ] Add `func cleanup(items: [StorageItem], dryRun: Bool) async throws -> [CleanupResult]`
- [ ] Default implementation: returns results with success=false and error="Not supported"
- [ ] Each analyzer overrides if it has a tool-specific deletion method

### 8.2 Implement cleanup per analyzer

| Analyzer | Cleanup method | Reinstall command |
|---|---|---|
| Homebrew | `brew uninstall --force <name>` | `brew install <name>` |
| Docker | `docker image rm <id>`, `docker volume rm <id>` | `docker pull <id>` |
| Node (nvm) | `nvm uninstall <version>` | `nvm install <version>` |
| Java (SDKMAN) | `sdk uninstall java <version>` | `sdk install java <version>` |
| Xcode | `rm -rf <DerivedData path>` (trash) | Auto-regenerated on build |
| Git repo | Move `.git` dir to Trash | Lost (warn explicitly) |
| Python (pyenv) | `pyenv uninstall <version>` | `pyenv install <version>` |
| Android | `sdkmanager --uninstall <pkg>` | `sdkmanager --install <pkg>` |
| Default | Move to `~/.Trash` via `FileManager.trashItem` | Path-based — can't reinstall |

- [ ] Homebrew: parse package name from path, run `brew uninstall`
- [ ] Docker: parse image/volume name, run `docker image rm` or `docker volume rm`
- [ ] Node: detect manager (nvm/fnm/Volta), run uninstall command
- [ ] Java: detect manager (SDKMAN/jEnv/asdf), run uninstall command
- [ ] Python: detect manager (pyenv/conda), run uninstall command
- [ ] Xcode/Android/caches: `FileManager.trashItem` (macOS native trash)
- [ ] Default fallback: `FileManager.trashItem` with explicit user warning

### 8.3 CleanupEngine

- [ ] `CleanupEngine` takes the list of registered analyzers
- [ ] `func preview(items: [StorageItem]) -> [CleanupResult]` — dry-run across all items
- [ ] `func execute(items: [StorageItem]) async -> [CleanupResult]` — real deletion
- [ ] For each item: finds the analyzer where `canCleanup()` returns true, delegates
- [ ] If no analyzer claims the item: falls back to `DefaultCleaner` (trash-based)
- [ ] Collects results, reports successes and failures

### 8.4 Safety checks (pre-execution)

Before any deletion, the engine validates:

- [ ] **Running process check:** For each item path, verify no process has an open file handle. Use `lsof +D <path>` or the existing `ProcessScanner`.
- [ ] **Confidence gate:** Items with confidence < 60% require explicit override. Show a second confirmation.
- [ ] **Project reference check:** Items referenced by 1+ projects require explicit override.
- [ ] **Dry-run is mandatory:** The UI always calls `preview()` first, shows results, then user confirms `execute()`.

### 8.5 Trash-based fallback

- [ ] Use `FileManager.trashItem(at:resultingItemURL:)` (macOS 10.8+) for generic filesystem cleanup
- [ ] This puts items in the user's Trash — they can recover from Finder
- [ ] Log what was trashed with original paths for undo tracking

### 8.6 Container wiring

- [ ] Add `CleanupEngine` to `DevSweepKit/Container`
- [ ] Expose via `AppViewModel` for UI consumption

## Acceptance Criteria

- `devsweep cleanup --preview homebrew:openjdk` shows what would happen without doing it
- `devsweep cleanup homebrew:openjdk` uninstalls the formula
- File-based items (caches, DerivedData) are moved to `~/.Trash`
- Docker images are removed via `docker image rm`
- Running process check blocks deletion of in-use items
- All existing tests pass

## Estimated: 3 sessions
