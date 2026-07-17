Instead, treat Claude Code like a senior engineer on your team, not an autonomous app
builder.

Recommended Development Workflow

Phase 1: Architecture First

Don't write any UI yet.

Start with the foundation.

Example prompt:

Read the attached specification.

Design a scalable architecture for this application.

Requirements:

● SwiftUI
● MVVM
● Plugin-based analyzer system
● Async/Await
● Dependency Injection
● Easily extensible analyzers
● macOS only

Do not implement anything yet.

Produce:

● Folder structure
● Module boundaries
● Core protocols
● Data models
● Dependency graph

Review and refine the architecture before writing code.

Phase 2: Project Scaffolding

Ask Claude to generate only the skeleton.

Create the project structure only.

No business logic.

No fake implementations.

Generate

App
Core
Services
Analyzers
Features
Models
Utilities

Create protocols.

Leave implementations empty.

This gives you a clean foundation.

Phase 3: Build One Feature at a Time

Avoid prompts like:

Build DevSweep.

Instead, use focused requests such as:

Implement the Homebrew analyzer.

Requirements:

● Detect Homebrew installation
● Calculate package sizes
● List formulae
● Use async/await
● Return standardized models
●

Include unit tests

Each analyzer should be a self-contained feature.

Phase 4: Review Every PR

Treat Claude's output like a pull request.

Ask questions such as:

Is this thread-safe?
●
Is this idiomatic Swift?
●
● Can this be simplified?
● Does this scale?
● Are there memory leaks?
●
●

Is this testable?
Is there unnecessary abstraction?

This review step often catches issues before they spread.

Plugin Architecture

One of the most important design decisions.

Define a protocol similar to:

protocol Analyzer {
var id: String { get }
var name: String { get }

    func scan() async throws -> AnalysisResult

}

Then implement analyzers like:

HomebrewAnalyzer
JavaAnalyzer
NodeAnalyzer
DockerAnalyzer
GitAnalyzer
XcodeAnalyzer
...

The app never needs to know implementation details.

It simply discovers analyzers and executes them.

Keep Models Generic

Instead of:

JavaResult
NodeResult
PythonResult

Prefer:

StorageItem

ToolInstallation

Dependency

Recommendation

Risk

AnalysisResult

This keeps the system flexible.

Build a CLI First

Before creating the UI, implement a command-line interface.

For example:

devsweep scan

Output:

{
"java": {...},
"docker": {...},
"node": {...}
}

Benefits:

● Easier to test
● Faster iteration
● UI becomes a presentation layer over proven logic

Suggested Milestones

Milestone 1

Infrastructure

● App shell
● Plugin loader
● Storage scanner
● Logging
● Dependency injection

Milestone 2

Core analyzers

● Homebrew
● Java
● Node
● Python

Milestone 3

Heavy analyzers

● Docker
● Xcode
● Android
● Git

Milestone 4

Project dependency scanner

This is the "wow" feature that connects installed tools to actual projects.

Milestone 5

Risk engine

Implement the confidence-based recommendation system.

Milestone 6

SwiftUI interface

Now connect the UI to the already-working backend.

Keep Documentation Up to Date

Have Claude maintain documents like:

docs/

Architecture.md

PluginSystem.md

AnalyzerAPI.md

DataModel.md

Roadmap.md

KnownIssues.md

This prevents knowledge from being trapped in conversations.

Use Git Aggressively

Keep commits small and focused.

For example:

feat: plugin architecture

feat: analyzer registry

feat: storage scanner

feat: homebrew analyzer

feat: java analyzer

feat: dashboard UI

If Claude goes off track, you can revert one feature without affecting the rest.

Create an AI Development Guide

Add a file such as CLAUDE.md in the repository. Claude Code automatically uses it as project
guidance.

Include things like:

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

This dramatically improves consistency across coding sessions.

One More Suggestion

Because this project could grow to 50,000+ lines of code, I'd structure it almost like a
commercial product from the start:

DevSweep

│
├── App
├── Core
│ ├── Models
│ ├── Protocols
│ ├── RiskEngine
│ ├── StorageEngine
│ └── ProjectScanner
│
├── Plugins
│ ├── Homebrew
│ ├── Java
│ ├── Node
│ ├── Python
│ ├── Docker
│ ├── Git
│ ├── Xcode
│ └── AI
│
├── UI
│
├── Tests
│
└── Docs

This keeps the project modular and allows you—or even outside contributors—to add new
analyzers without touching the rest of the application. It also aligns well with your long-term
vision of making DevSweep a comprehensive developer environment manager rather than just
another cleanup utility.
