# Milestone 6: SwiftUI App

**Goal:** A native macOS app that wraps the CLI backend. The UI is a presentation layer — all logic already exists and is tested.

## Architecture

```
UI/
├── App/
│   └── DevSweepApp.swift        # @main App, NSApplicationDelegate
├── ViewModels/
│   ├── DashboardViewModel       # Aggregated storage overview
│   ├── AnalyzerListViewModel    # Per-analyzer detail views
│   ├── RecommendationViewModel  # Sorted recommendations
│   └── ScanProgressViewModel    # Background scan state
├── Views/
│   ├── ContentView              # Sidebar + main area
│   ├── DashboardView            # Home screen with summary cards
│   ├── AnalyzerDetailView       # Drill-down per analyzer
│   ├── RecommendationListView   # "What can I clean?"
│   ├── ProjectGraphView         # Dependency graph visualization
│   └── SettingsView             # Scan paths, analyzer toggles
├── Components/
│   ├── StorageCard               # Reusable size display card
│   ├── ConfidenceBadge           # Color-coded confidence indicator
│   ├── SizeChart                 # Horizontal bar chart
│   └── ScanProgressBar           # Animated progress
└── Theme/
    └── DevSweepColors.swift     # App color palette
```

## Tasks

### 6.1 App shell
- [ ] macOS SwiftUI app target in Package.swift (or Xcode project)
- [ ] Sidebar navigation: Dashboard, Storage, Projects, per-analyzer entries
- [ ] `AppState` as `@Observable` class injected via `.environment()`
- [ ] Menu bar: File, View, Help
- [ ] App icon placeholder

### 6.2 Background scanning
- [ ] `ScanService` wraps CLI `devsweep scan` (or direct library call)
- [ ] Scan runs on launch and on manual "Refresh" button
- [ ] Progress reporting: bytes scanned, analyzers completed
- [ ] Scan on background queue, updates published to main actor
- [ ] Handle scan errors gracefully (show banner, don't crash)

### 6.3 Dashboard view
- [ ] Summary cards: total developer storage, potentially recoverable, tool count
- [ ] Per-ecosystem breakdown (Java: 18GB, Node: 9GB, etc.)
- [ ] "Last scan: 2 minutes ago" with manual refresh button
- [ ] Quick-jump to top recommendations

### 6.4 Analyzer detail view
- [ ] Select an analyzer from sidebar → detail view
- [ ] Shows: detected installations, sizes, versions, status
- [ ] For each item: size, last used, confidence badge, recommendation text
- [ ] Empty state: "No Node installation detected"

### 6.5 Recommendation list view
- [ ] Sorted list of all recommendations across all analyzers
- [ ] Filter: All / Safe to Remove / Consider / Keep
- [ ] Sort: Size (largest first), Confidence (highest first), Name
- [ ] Each row: item name, size, confidence badge, one-line reason

### 6.6 Settings
- [ ] Toggle individual analyzers on/off
- [ ] Configure scan paths for project scanner
- [ ] Export scan as JSON button

### 6.7 Polish
- [ ] Animated scan progress
- [ ] Window title updates during scan
- [ ] Dock badge shows recoverable space
- [ ] Keyboard shortcuts: Cmd+R refresh, Cmd+F search
- [ ] Accessibility labels on all interactive elements

## Acceptance Criteria
- App launches and shows dashboard
- Scan completes within 30 seconds on a typical dev machine
- Memory under 300 MB
- Clicking through sidebar → detail views works
- Recommendations load and filter correctly
- Settings persist across launches

## Estimated: 4 sessions
