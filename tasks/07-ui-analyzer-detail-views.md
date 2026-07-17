# Milestone 7: UI — Analyzer Detail Views

**Goal:** Every analyzer in the sidebar is clickable and navigates to a detail view showing individual items with their sizes, dates, confidence scores, and the full risk "story."

**Problem:** Currently, clicking "Homebrew 79" or "Java 2" in the sidebar does nothing. The only views are Dashboard and Recommendations. Users can't drill into what the 79 Homebrew packages actually are.

## Tasks

### 7.1 Sidebar navigation for analyzers

- [ ] Add `case analyzer(String)` to the ContentView.Tab enum (parameterized by analyzer ID)
- [ ] Clicking an analyzer row in the sidebar sets `selectedTab = .analyzer(result.analyzerId)`
- [ ] The detail area switches on `.analyzer(id)` and renders `AnalyzerDetailView(id: id)`
- [ ] Back-navigation: clicking "Dashboard" returns to the summary

### 7.2 AnalyzerDetailView

For a selected analyzer, show:

```
┌──────────────────────────────────────────────────────┐
│  ← Dashboard                                         │
│                                                      │
│  Homebrew                                  3.7 GB    │
│  79 packages   5 running services                    │
│                                                      │
│  ┌──────────────────────────────────────────────┐    │
│  │ /opt/homebrew/Cellar/openjdk    1.2 GB       │    │
│  │ Modified Jul 12    [Safe 71%]                │    │
│  │                                               │    │
│  │ + Managed by Homebrew — easy to reinstall     │    │
│  │ + Not referenced by any project               │    │
│  │ - Active process using this path              │    │
│  └──────────────────────────────────────────────┘    │
│  ┌──────────────────────────────────────────────┐    │
│  │ /opt/homebrew/Cellar/node@20     892 MB      │    │
│  │ Modified Jun 3     [Consider 65%]             │    │
│  │ + Managed by Homebrew                         │    │
│  │ - Referenced by 2 projects                    │    │
│  └──────────────────────────────────────────────┘    │
│  ...                                                 │
└──────────────────────────────────────────────────────┘
```

- [ ] Title bar: analyzer name, total size, package count
- [ ] List: one row per StorageItem from that analyzer's AnalysisResult
- [ ] Each row: path (home-relative), size (formatted), last modified, confidence badge
- [ ] Expanded row: full list of risk factors for/against (uses the Recommendation for that path)
- [ ] Empty state: "No items found" when analyzer returned zero items (e.g., Android not installed)

### 7.3 ItemRow component

Reusable component used by AnalyzerDetailView and future CleanupView:

- [ ] Shows: path (truncated, home-relative), sizeMB, last modified date, ConfidenceBadge
- [ ] Tappable to expand/collapse the risk factor details
- [ ] Expand shows: list of `+` reasons (safe) and `-` reasons (keep), with factor names
- [ ] If no recommendation exists for that path: show "No risk data — run a scan first"

### 7.4 Recommendation lookup

The `AppViewModel` currently stores `results: [AnalysisResult]` and `recommendations: [Recommendation]` separately. The detail view needs to match them.

- [ ] Add `func recommendations(for analyzerId: String) -> [(StorageItem, Recommendation?)]` to AppViewModel
- [ ] Joins results items with their corresponding recommendation by path
- [ ] Handles missing recommendations (null — shows "No data")

### 7.5 Visual polish

- [ ] Animated expand/collapse on item rows
- [ ] Size bar chart per item (horizontal bar proportional to item size vs analyzer total)
- [ ] Empty state illustrations for analyzers with no data

## Acceptance Criteria

- Clicking "Homebrew" in the sidebar shows 79 individual items with sizes and confidence
- Clicking an item row expands to show the risk factors
- Clicking "Android" shows "No SDK found" (if not installed)
- Shift+click back to Dashboard returns to summary cards
- Existing tests still pass

## Estimated: 2 sessions
