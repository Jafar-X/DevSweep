import Foundation

// MARK: - Running Process

public struct RunningProcessFactor: RiskFactor {
    public let name = "Running Process"

    public init() {}

    public func assess(item: StorageItem, context: RiskContext) -> RiskImpact {
        let isRunning = context.runningProcessPaths.contains { procPath in
            procPath.hasPrefix(item.path) || item.path.hasPrefix(procPath)
        }
        if isRunning {
            return .keep(reason: "Active process using this path")
        }
        return .neutral
    }
}

// MARK: - Project Reference

public struct ProjectReferenceFactor: RiskFactor {
    public let name = "Project Reference"

    public init() {}

    public func assess(item: StorageItem, context: RiskContext) -> RiskImpact {
        guard let graph = context.dependencyGraph else { return .neutral }
        let toolName = toolFromPath(item.path)
        let projects = graph.projectsUsing(tool: toolName)
        if !projects.isEmpty {
            return .keep(reason: "Used by \(projects.count) project(s)")
        }
        if graph.projects.isEmpty {
            return .neutral  // No project scan data available
        }
        return .safe(reason: "Not referenced by any project")
    }

    private func toolFromPath(_ path: String) -> String {
        let lower = path.lowercased()
        for tool in ["java", "node", "python", "go", "rust", "ruby", "php"] {
            if lower.contains(tool) { return tool }
        }
        return "unknown"
    }
}

// MARK: - Recent Use

public struct RecentUseFactor: RiskFactor {
    public let name = "Recent Use"

    public init() {}

    public func assess(item: StorageItem, context: RiskContext) -> RiskImpact {
        let daysSinceAccess = Date().timeIntervalSince(item.lastAccessed) / 86400
        if daysSinceAccess <= 7 {
            return .keep(reason: "Accessed \(Int(daysSinceAccess)) day(s) ago")
        }
        if daysSinceAccess >= 90 {
            return .safe(reason: "Last accessed \(Int(daysSinceAccess)) day(s) ago")
        }
        return .neutral
    }
}

// MARK: - Package Manager

public struct PackageManagerFactor: RiskFactor {
    public let name = "Package Manager"

    public init() {}

    public func assess(item: StorageItem, context: RiskContext) -> RiskImpact {
        let lower = item.path.lowercased()
        if lower.contains("/cellar/") || lower.contains("/caskroom/") {
            return .safe(reason: "Managed by Homebrew — easy to reinstall")
        }
        if lower.contains(".nvm/") || lower.contains(".pyenv/") || lower.contains(".sdkman/") {
            return .safe(reason: "Managed by version manager — easy to reinstall")
        }
        if lower.contains("/npm/_cacache") || lower.contains("caches/pip") || lower.contains(".gradle/caches") {
            return .safe(reason: "Package manager cache — safe to clear")
        }
        return .neutral
    }
}

// MARK: - System Component

public struct SystemComponentFactor: RiskFactor {
    public let name = "System Component"

    private let systemPrefixes: Set<String> = [
        "/usr/bin", "/usr/lib", "/usr/sbin",
        "/bin", "/sbin", "/System",
    ]

    public init() {}

    public func assess(item: StorageItem, context: RiskContext) -> RiskImpact {
        for prefix in systemPrefixes {
            if item.path.hasPrefix(prefix) {
                return .keep(reason: "System component — do not remove")
            }
        }
        return .neutral
    }
}

// MARK: - Cache Type

public struct CacheTypeFactor: RiskFactor {
    public let name = "Cache Type"

    private let cachePatterns: [(String, String)] = [
        ("DerivedData", "Xcode derived data — safe to clear"),
        ("/Archives/", "Xcode archive — safe to remove"),
        ("CoreSimulator/Devices", "Simulator data — recreatable"),
        ("_cacache", "npm cache — safe to clear"),
        (".pnpm-store", "pnpm store — safe to clear"),
        ("Caches/Yarn", "Yarn cache — safe to clear"),
        ("Caches/pip", "pip cache — safe to clear"),
        (".gradle/caches", "Gradle cache — safe to clear"),
        ("docker://", "Docker resource — inspect before removal"),
    ]

    public init() {}

    public func assess(item: StorageItem, context: RiskContext) -> RiskImpact {
        for (pattern, reason) in cachePatterns {
            if item.path.contains(pattern) {
                return .safe(reason: reason)
            }
        }
        return .neutral
    }
}

// MARK: - Install Method

public struct InstallMethodFactor: RiskFactor {
    public let name = "Install Method"

    public init() {}

    public func assess(item: StorageItem, context: RiskContext) -> RiskImpact {
        // Directories under known manual install locations are higher risk
        let manualPrefixes = [
            "/usr/local/Cellar",
            "/opt/homebrew/Cellar",
        ]
        for prefix in manualPrefixes {
            if item.path.hasPrefix(prefix) {
                return .neutral  // Homebrew is managed; covered by PackageManagerFactor
            }
        }
        return .neutral  // Most paths are neutral for this factor
    }
}

// MARK: - Version Age

public struct VersionAgeFactor: RiskFactor {
    public let name = "Version Age"

    public init() {}

    public func assess(item: StorageItem, context: RiskContext) -> RiskImpact {
        let daysSinceModified = Date().timeIntervalSince(item.lastModified) / 86400
        if daysSinceModified > 365 {
            return .safe(reason: "Not modified in over a year")
        }
        return .neutral
    }
}
