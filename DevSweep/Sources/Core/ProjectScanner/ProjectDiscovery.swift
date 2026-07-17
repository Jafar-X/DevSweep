import Foundation

/// Scans directories for project manifest files.
public final class ProjectDiscovery: @unchecked Sendable {
    private let fileManager: FileManager

    /// File names recognized as project roots.
    public static let manifestNames: Set<String> = [
        "package.json",
        "pom.xml",
        "build.gradle",
        "build.gradle.kts",
        "Cargo.toml",
        "go.mod",
        "requirements.txt",
        "pyproject.toml",
        "setup.py",
        "Gemfile",
        "Podfile",
        "composer.json",
    ]

    private let skipDirs: Set<String> = [
        "node_modules", ".build", "DerivedData", ".cache",
        "vendor", "Pods", ".swiftpm", "__pycache__",
        ".git", ".hg", ".svn",
    ]

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Recursively find manifest files up to a given depth.
    /// Returns [(manifestURL, projectRootURL)].
    public func discover(in roots: [URL], maxDepth: Int = 4) -> [(manifest: URL, root: URL)] {
        var results: [(URL, URL)] = []

        for root in roots {
            guard fileManager.fileExists(atPath: root.path) else { continue }
            walk(root, rootPath: root, currentDepth: 0, maxDepth: maxDepth, results: &results)
        }

        return results
    }

    private func walk(
        _ dir: URL,
        rootPath: URL,
        currentDepth: Int,
        maxDepth: Int,
        results: inout [(URL, URL)]
    ) {
        guard currentDepth <= maxDepth else { return }

        let name = dir.lastPathComponent
        if skipDirs.contains(name) { return }
        if name.hasPrefix(".") && name != "." { return }

        // Check for manifests in this directory
        for manifestName in Self.manifestNames {
            let manifestURL = dir.appendingPathComponent(manifestName)
            if fileManager.fileExists(atPath: manifestURL.path) {
                results.append((manifestURL, dir))
            }
        }

        // Recurse
        guard let contents = try? fileManager.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        ) else { return }

        for child in contents {
            var isDir: ObjCBool = false
            guard fileManager.fileExists(atPath: child.path, isDirectory: &isDir),
                  isDir.boolValue
            else { continue }
            walk(child, rootPath: rootPath, currentDepth: currentDepth + 1, maxDepth: maxDepth, results: &results)
        }
    }
}
