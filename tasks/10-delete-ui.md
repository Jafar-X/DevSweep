# Milestone 10: Delete UI

**Goal:** Connect the cleanup engine to the UI. Users can select items from any analyzer detail view, add them to a "Cleanup cart," review everything, and delete with proper confirmation.

## UI Flow

```
Analyzer Detail (Homebrew)
  │
  ├── ☑ /opt/homebrew/Cellar/openjdk    1.2 GB  [Safe 71%]
  ├── ☑ /opt/homebrew/Cellar/node@18    892 MB  [Safe 82%]
  ├── ☐ /opt/homebrew/Cellar/python@3.12 445 MB [Keep 45%]
  │
  │  2 items selected   2.0 GB
  │  [ Add to Cleanup ]
  │
  ▼
Cleanup Page
  │
  │  Items to remove                    Recover 4.3 GB
  │  ──────────────────────────────────────────────
  │  ☑ Homebrew / openjdk         1.2 GB  Safe 71%
  │      $ brew install openjdk@17
  │  ☑ Homebrew / node@18          892 MB  Safe 82%
  │      $ nvm install 18
  │  ☑ Junk / Caches / Yarn       1.7 GB  Safe 98%
  │      Apps regenerate this on next launch
  │  ☑ Xcode / DerivedData          512 MB  Safe 88%
  │      Rebuilds on next compile
  │
  │  4 items selected   4.3 GB
  │  [ Delete Selected ]
  │
  ▼
Confirmation Modal
  │
  │  Delete 4 items?
  │  This will free 4.3 GB.
  │
  │  These items can be recovered from Trash.
  │
  │  Cat photos in Downloads will NOT be deleted.
  │  Running processes will NOT be touched.
  │
  │  [ Cancel ]    [ Delete 4 Items ]
```

## Tasks

### 10.1 Selection on analyzer detail views

- [ ] Add a `@State var selectedPaths: Set<String>` to each AnalyzerDetailView
- [ ] Each ItemRow gets a checkbox (toggle) on the leading edge
- [ ] Footer bar: "N items selected (X.X GB)  [Add to Cleanup]"
- [ ] Tapping "Add to Cleanup" pushes the selected items into `AppViewModel.cleanupCart`

### 10.2 CleanupCart in AppViewModel

- [ ] `var cleanupCart: [(StorageItem, Recommendation?)]` — items the user has added
- [ ] `var cleanupTotalMB: Double` — computed from cart
- [ ] `func addToCart(_ items: [(StorageItem, Recommendation?)])`
- [ ] `func removeFromCart(_ path: String)`
- [ ] `func clearCart()`
- [ ] Persists across view navigation (cart survives switching tabs)

### 10.3 CleanupView (new sidebar tab)

- [ ] New sidebar entry: "Cleanup" with a trash icon, badge showing item count
- [ ] Lists all items in the cart, grouped by analyzer/source
- [ ] Each item shows: analyzer name, path, size, confidence badge, reinstall command
- [ ] Swipe to remove individual items from cart
- [ ] Footer: total selected, total recoverable, [Delete Selected] button
- [ ] Empty state: "No items selected. Add items from analyzer detail views."

### 10.4 Confirmation modal

- [ ] Full-screen sheet or large alert
- [ ] Shows: count of items, total GB to be freed
- [ ] Shows: per-item summary (name, size, reinstall command)
- [ ] Shows: safety notes — "Moved to Trash", "Running processes excluded"
- [ ] Two buttons: Cancel (default) and "Delete N Items" (destructive, red)
- [ ] After deletion: shows results (successes and failures)

### 10.5 Deletion execution

- [ ] `AppViewModel.deleteCart()` → calls `CleanupEngine.execute()`
- [ ] Runs `preview()` first (mandatory dry-run before real execution)
- [ ] Shows progress indicator during deletion
- [ ] Results sheet: "Deleted X items, freed Y GB. Z items could not be deleted (in use)."
- [ ] Clears cart on success, keeps failed items for retry

### 10.6 Junk integration

- [ ] Junk analyzer detail view works like any other: select items → Add to Cleanup
- [ ] Junk items are always high confidence (90%+) — shown in green
- [ ] Cleanup is always `trashItem` — no tool commands needed

## Acceptance Criteria

- Select 3 Homebrew items, click "Add to Cleanup", see them on the Cleanup page
- Cleanup page shows reinstall commands for each item
- Clicking "Delete Selected" shows a confirmation modal
- Confirming deletion actually frees the space (verify with `df -h` or Finder)
- Failed deletions (process in use) are reported with a clear reason
- Cart survives tab switching
- All existing tests pass

## Estimated: 3 sessions
