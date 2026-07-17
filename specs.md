DevSweep

Vision

DevSweep is a macOS application that intelligently analyzes, manages, and optimizes
developer environments.

Unlike CleanMyMac or DaisyDisk, DevSweep understands developer tooling, SDKs, package
managers, caches, virtual environments, containers, IDEs, and project dependencies.

The goal is to let developers answer one simple question:

"What is taking up my developer storage, what depends on it, and what can I
safely remove?"

Target Platform

●  macOS 14+
●  Apple Silicon (primary)
Intel (secondary)
●

Language:

●  Swift
●  SwiftUI

Architecture

●  MVVM
●  Async/Await
●  Modular Architecture

Core Principles

Never Guess

Never tell the user something is safe.

Instead provide

●  Confidence Score
●  Reason
●  Dependencies
●  Last Usage
●  Recommendation

Example

Java 17

Installed By:
Homebrew

Projects Using:
3

Running Processes:
0

Last Used:
Yesterday

Recommendation

Keep Installed

Confidence
99%

Read-Only First

V1 performs zero destructive actions.

Only analyze.

Deletion is introduced in V2.

Everything Explainable

Every recommendation must answer

Why?

Example

Node 16

Recommendation

Safe to Remove

Why

• No projects use Node 16
• Last executed 487 days ago
• Installed via NVM
• No running process

Dashboard

Home screen

Developer Storage

Java
18.4 GB

Node
9.8 GB

Python
11.2 GB

Docker
42.3 GB

Android
27 GB

Xcode
36 GB

Rust
4 GB

Go
2 GB

Caches
18 GB

Potentially Recoverable

96 GB

Modules

1. Storage Scanner

Scans

/opt/homebrew
/usr/local

~/Library

~/.cache

~/.m2

~/.gradle

~/.cargo

~/.rustup

~/.npm

~/.pnpm-store

~/go

~/Library/Developer

~/Library/Containers

~/Library/Application Support

Calculates

●  Size
●  File count
●  Last modified
●  Last access
●  Owner

2. Homebrew Module

Collect

brew list

brew leaves

brew info

brew deps

brew services

brew doctor

Display

Installed Formulae

Installed Casks

Versions

Dependencies

Running Services

Unused Formulae

Old Versions

Potential Cleanup

3. Java Module

Detect

Oracle

Homebrew

SDKMAN

jEnv

asdf

Manual Installations

Display

Installed JDKs

Version

Architecture

Installation Method

Used By

Projects

Processes

Recommendation

4. Node Module

Support

nvm

fnm

Volta

asdf

brew

Detect

Installed Node Versions

Global Packages

Global Cache

npm Cache

pnpm Store

Yarn Cache

Corepack

5. Python Module

Support

pyenv

uv

Homebrew

System Python

Anaconda

Detect

Virtual Environments

Installed Versions

Pip Cache

Package Cache

Unused Environments

6. Docker Module

Display

Images

Containers

Volumes

Networks

Builder Cache

Unused Images

Dangling Volumes

Recoverable Storage

7. Xcode Module

Analyze

DerivedData

Archives

Simulators

Runtime Images

Device Support

Documentation

Swift Package Cache

8. Android Module

Analyze

SDKs

NDKs

Platform Tools

Build Tools

Emulators

Snapshots

Gradle Cache

AVDs

9. IDE Module

JetBrains

IntelliJ

Android Studio

WebStorm

CLion

PyCharm

VS Code

Cursor

Windsurf

Detect

Extensions

Plugins

Caches

Logs

Old Versions

10. AI Development Tools

Analyze

Claude Code

Codex CLI

Gemini CLI

Ollama

LM Studio

Continue

Aider

Cursor AI

OpenHands

Detect

Downloaded Models

Prompt History (size only)

Caches

Logs

Sessions

Embeddings

Model Storage

11. Git Module

Analyze

Large Repositories

Worktrees

LFS

Orphan Branches

Git Cache

Repository Sizes

12. Kubernetes

Analyze

Kind

Minikube

Colima

Docker Desktop

Kubeconfig

Helm Cache

Kubectl Cache

Images

Volumes

13. Terraform

Analyze

Terraform Plugins

Provider Cache

Downloaded Modules

14. Databases

Support

Postgres

MySQL

MariaDB

MongoDB

Redis

ElasticSearch

Analyze

Installed Versions

Data Directory

Logs

Running State

15. Project Scanner

Search

package.json

pom.xml

build.gradle

Cargo.toml

go.mod

requirements.txt

pyproject.toml

Gemfile

Podfile

composer.json

Infer

Programming Language

Framework

SDK Version

Package Manager

Dependencies

Last Opened

Dependency Graph

Example

Java 21

Used By

Project A

Project B

Project C

Node 22

Used By

Frontend

Admin Panel

Landing Page

Risk Engine

Every recommendation has

Confidence Score

Safe

Likely Safe

Needs Review

Dangerous

Factors

Running Process

Referenced by Project

Recently Used

Package Manager Dependency

System Component

Install Method

Version Age

Search

Global Search

java

postgres

docker

cache

jdk17

node20

python

Timeline

Example

Yesterday

Installed Node 22

2 Weeks Ago

Downloaded Docker Image

6 Months Ago

Installed Java 21

1 Year Ago

Last Used Python 3.10

Future V2

Enable cleanup

Each cleanup

Preview

Estimated Space

Confirmation

Rollback (where possible)

Future V3

Project Dependency Engine

Automatically determine

Java 17

Required By

3 Projects

Node 18

No Project Uses

Safe

Future V4

Machine Migration

Export

Installed SDKs

Node Versions

Python Versions

JDKs

Homebrew Packages

VSCode Extensions

Cursor Extensions

Docker Images

Kubernetes Contexts

Import to another Mac.

UI

Sidebar

Dashboard

Storage

Projects

Homebrew

Java

Node

Python

Docker

Xcode

Android

Git

AI Tools

Databases

Kubernetes

Settings

Performance Goals

Initial scan under 30 seconds
Incremental scan under 3 seconds

●
●
●  Memory usage under 300 MB
●  Support >500 GB developer environments
●  Async scanning
●  Background indexing

Security

●  Never upload user files.
●  All analysis performed locally.
●  No telemetry by default.
●  Optional anonymous crash reports.
●  Require explicit confirmation before any destructive action.
●  Clearly distinguish between cache removal, uninstalling software, and deleting

user-created data.

Stretch Goals

Interactive storage treemap.

●
●  Time Machine integration to compare storage growth over time.
●  Spotlight-style quick search for installed developer tools.
●  Launch agents/services viewer (launchd, Homebrew services, login items).
●  Duplicate SDK detection (e.g., multiple JDKs installed through different managers).
●
●  Scheduled health reports ("Your developer environment grew by 12 GB this week.").
●  Export scan results as JSON or Markdown.
●  Plugin architecture so new ecosystems (e.g., Bun, Deno, Zig, Flutter, .NET, Unity) can be

"Why is this installed?" graph showing dependency chains.

added independently.

One suggestion that could make this stand out

I would design the core around a plugin-based analyzer architecture from day one.

Instead of hardcoding support for Java, Node, Docker, etc., define a common interface like:

Analyzer
├── Homebrew
├── Java
├── Node
├── Python
├── Docker
├── Git
├── AI Tools
├── Xcode
└── ...

Each analyzer would be responsible for:

●  Discovering installations.
●  Calculating storage usage.
●  Determining dependencies.
●  Assessing cleanup safety.
●  Returning standardized results.

That makes it much easier to add support for new ecosystems (such as Bun, Deno, Flutter,
.NET, Unity, or future AI tooling) without changing the rest of the application. It also makes the
project significantly more maintainable as it grows.


