# DevSweep Development Rules

## General

- Swift 6
- SwiftUI
- MVVM
- Async/Await
- No third-party dependencies unless approved.
- Prefer native macOS APIs.

## Architecture

- Business logic must not depend on SwiftUI.
- Every analyzer implements the Analyzer protocol.
- UI only consumes view models.
- Never access the filesystem directly from views.

## Coding Style

- Favor composition over inheritance.
- Avoid force unwraps.
- Add documentation comments to public types.
- Add unit tests for all analyzers.
