# Milestone 5: Risk Engine

**Goal:** Every storage item and installed tool gets a confidence-scored recommendation. Nothing is "safe to delete" — everything has evidence-based reasoning.

## Risk Model

```
Confidence Score: 0..100
  Safe (80-100)      → Almost certainly removable
  Likely Safe (60-79)→ Look OK but double-check
  Needs Review (40-59) → Too many unknowns
  Dangerous (0-39)  → Don't touch without expert review
```

## Tasks

### 5.1 Risk factors
- [ ] `protocol RiskFactor` — `func assess(item: StorageItem, context: ScanContext) -> RiskAssessment`
- [ ] Implement these factors:

| Factor | Reduces Risk (more removable) | Increases Risk (less removable) |
|---|---|---|
| `RunningProcessFactor` | No running process using this path | Active process holding file open |
| `ProjectReferenceFactor` | Zero projects depend on it | 1+ projects list it as dependency |
| `RecentUseFactor` | Last accessed > 90 days ago | Last accessed < 7 days ago |
| `PackageManagerFactor` | Installed manually (no manager tracking) | Managed by Homebrew/apt/etc. |
| `SystemComponentFactor` | Not in system paths | In `/usr/bin`, `/bin`, `/System` |
| `VersionAgeFactor` | Version is outdated (2+ major versions behind) | Latest stable version |
| `InstallMethodFactor` | Version manager (easy to reinstall) | Manual install, custom build |
| `CacheTypeFactor` | Well-known cache directory | Unusual or undocumented location |

### 5.2 Risk engine
- [ ] `RiskEngine` aggregates all factors
- [ ] `func evaluate(item: StorageItem, context: ScanContext) -> Recommendation`
- [ ] Each `Recommendation` contains:
  - `verdict: Verdict` (keep / consider-removing / safe-to-remove)
  - `confidence: Int` (0-100)
  - `factors: [String]` — human-readable reasons
  - `conflictingFactors: [String]` — reasons against removal

### 5.3 Enhanced AnalysisResult
- [ ] Extend `AnalysisResult` to carry `[Recommendation]` alongside `[StorageItem]`
- [ ] Summary fields: `potentiallyRecoverableBytes`, `safeToRemoveBytes`, `needsReviewBytes`
- [ ] Analyzers now produce recommendations, not just raw items

### 5.4 CLI enhancements
- [ ] `devsweep scan` includes recommendations in output
- [ ] `devsweep recommend` — sorted list of recommendations, largest recoverable first
- [ ] `devsweep explain <item>` — detailed reasoning for a specific item

### 5.5 Unit tests
- [ ] Test each factor in isolation with known inputs
- [ ] Test combined risk engine: given these 5 factors, the recommendation is "Safe to Remove" at 87%
- [ ] Test edge cases: empty state, all unknown factors, contradictory signals
- [ ] Golden file test: scan a known fixture, verify recommendations match expected output

## Acceptance Criteria
```bash
devsweep recommend | head -5
# Lists top 5 recoverable items with confidence scores

devsweep explain homebrew:node@16
# Shows all factors and reasoning chain
```

Risk engine test suite: 8 factor tests + integration test pass.

## Estimated: 2 sessions
