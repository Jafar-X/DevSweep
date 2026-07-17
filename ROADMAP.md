# DevSweep Roadmap

Build order is sequential. Each milestone produces a runnable, testable artifact.

| # | Milestone | Goal | Key Deliverable |
|---|---|---|---|
| 1 | Infrastructure | App shell, plugin system, storage scanner | CLI: `devsweep scan` outputs JSON |
| 2 | Core Analyzers | Homebrew, Java, Node, Python | 4 analyzers, 4 test suites |
| 3 | Heavy Analyzers | Docker, Xcode, Android, Git | 8 total analyzers running |
| 4 | Project Scanner | Map tools → projects | Dependency graph |
| 5 | Risk Engine | Confidence scores, recommendations | Every finding has a verdict |
| 6 | SwiftUI App | Full macOS app over proven backend | Ship v1 |

| 7 | UI: Analyzer Detail Views | Drilled-down per-item view with full risk story | Every sidebar item is clickable |
| 8 | Cleanup Engine | Safe deletion via analyzers, trash-based, reinstall recipes | `cleanup()` on every analyzer |
| 9 | Junk Analyzer | Cache/log/temp/trash scanner | Junk categories added to dashboard |
| 10 | Delete UI | Selection, confirmation modal, delete button | End-to-end safe cleanup |

## V1 (complete)

| # | Milestone | Goal | Key Deliverable |
|---|---|---|---|
| 1 | Infrastructure | App shell, plugin system, storage scanner | CLI: `devsweep scan` outputs JSON |
| 2 | Core Analyzers | Homebrew, Java, Node, Python | 4 analyzers, 4 test suites |
| 3 | Heavy Analyzers | Docker, Xcode, Android, Git | 8 total analyzers running |
| 4 | Project Scanner | Map tools → projects | Dependency graph |
| 5 | Risk Engine | Confidence scores, recommendations | Every finding has a verdict |
| 6 | SwiftUI App | Full macOS app over proven backend | Ship v1 |

## Rules

- **Every milestone ends with a passing test suite.**
- **No milestone starts before the previous one is complete.**
- **No UI code in milestones 1-5.**
- **Each analyzer is one self-contained PR.**
