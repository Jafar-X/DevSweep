import Foundation

/// Parses a project manifest file and returns a Project.
public protocol ManifestParser: Sendable {
    func parse(_ file: URL) async -> Project?
}

/// Registry of parsers that tries each one until a match is found.
public final class ManifestParserRegistry: Sendable {
    private let parsers: [any ManifestParser]

    public init(parsers: [any ManifestParser]) {
        self.parsers = parsers
    }

    public func parse(_ file: URL) async -> Project? {
        for parser in parsers {
            if let project = await parser.parse(file) { return project }
        }
        return nil
    }
}

// MARK: - Individual parsers

public struct NodePackageParser: ManifestParser {
    public init() {}

    public func parse(_ file: URL) async -> Project? {
        guard file.lastPathComponent == "package.json",
              let data = try? Data(contentsOf: file),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        let name = (json["name"] as? String) ?? file.deletingLastPathComponent().lastPathComponent
        var deps: [ProjectDependency] = []

        if let engines = json["engines"] as? [String: String],
           let nodeVer = engines["node"] {
            deps.append(ProjectDependency(tool: "node", versionConstraint: nodeVer))
        }

        return Project(name: name, path: file.path, language: "node", dependencies: deps)
    }
}

public struct MavenParser: ManifestParser {
    public init() {}

    public func parse(_ file: URL) async -> Project? {
        guard file.lastPathComponent == "pom.xml",
              let data = try? Data(contentsOf: file)
        else { return nil }

        let xml = String(data: data, encoding: .utf8) ?? ""
        var deps: [ProjectDependency] = []

        if let javaVer = firstTagValue("java.version", in: xml)
            ?? firstTagValue("maven.compiler.source", in: xml) {
            deps.append(ProjectDependency(tool: "java", versionConstraint: javaVer))
        }

        if let jvmVer = firstTagValue("jvm.version", in: xml) {
            deps.append(ProjectDependency(tool: "java", versionConstraint: jvmVer))
        }

        let name = file.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent
        return Project(name: name, path: file.path, language: "java", dependencies: deps)
    }

    private func firstTagValue(_ tag: String, in xml: String) -> String? {
        guard let range = xml.range(of: "<\(tag)>"),
              let end = xml.range(of: "</\(tag)>", range: range.upperBound..<xml.endIndex)
        else { return nil }
        return String(xml[range.upperBound..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public struct GradleParser: ManifestParser {
    public init() {}

    public func parse(_ file: URL) async -> Project? {
        let name = file.lastPathComponent
        guard name == "build.gradle" || name == "build.gradle.kts",
              let content = try? String(contentsOf: file, encoding: .utf8)
        else { return nil }

        var deps: [ProjectDependency] = []

        let patterns = [
            #"sourceCompatibility\s*[=:]\s*['"]?(\d+\.?\d*)"#,
            #"targetCompatibility\s*[=:]\s*['"]?(\d+\.?\d*)"#,
            #"JavaLanguageVersion\.of\((\d+)\)"#,
            #"javaVersion\s*=\s*JavaVersion\.VERSION_(\d+)"#,
        ]
        for pattern in patterns {
            if let match = content.range(of: pattern, options: .regularExpression) {
                let matched = String(content[match])
                if let num = matched.components(separatedBy: CharacterSet.decimalDigits.inverted)
                    .filter({ !$0.isEmpty }).first {
                    deps.append(ProjectDependency(tool: "java", versionConstraint: num))
                    break
                }
            }
        }

        let projName = file.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent
        return Project(name: projName, path: file.path, language: "java", dependencies: deps)
    }
}

public struct CargoParser: ManifestParser {
    public init() {}

    public func parse(_ file: URL) async -> Project? {
        guard file.lastPathComponent == "Cargo.toml",
              let content = try? String(contentsOf: file, encoding: .utf8)
        else { return nil }

        var deps: [ProjectDependency] = []
        let rustPattern = #"rust-version\s*=\s*['"](\d+\.\d+)"#
        if let match = content.range(of: rustPattern, options: .regularExpression) {
            let line = String(content[match])
            let ver = line.split(separator: "\"").dropFirst().first.map(String.init)
            if let v = ver { deps.append(ProjectDependency(tool: "rust", versionConstraint: v)) }
        }

        let name = file.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent
        return Project(name: name, path: file.path, language: "rust", dependencies: deps)
    }
}

public struct GoModParser: ManifestParser {
    public init() {}

    public func parse(_ file: URL) async -> Project? {
        guard file.lastPathComponent == "go.mod",
              let content = try? String(contentsOf: file, encoding: .utf8)
        else { return nil }

        var deps: [ProjectDependency] = []
        let goPattern = #"^go (\d+\.\d+)"#
        if let match = content.firstMatch(of: try! Regex(goPattern).anchorsMatchLineEndings()),
           let ver = match.output[1].substring {
            deps.append(ProjectDependency(tool: "go", versionConstraint: String(ver)))
        }

        let name = file.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent
        return Project(name: name, path: file.path, language: "go", dependencies: deps)
    }
}

public struct PythonManifestParser: ManifestParser {
    public init() {}

    public func parse(_ file: URL) async -> Project? {
        let name = file.lastPathComponent
        guard name == "pyproject.toml" || name == "setup.py" || name == "requirements.txt"
        else { return nil }

        let deps = [ProjectDependency(tool: "python", versionConstraint: nil)]
        let projName = file.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent
        return Project(name: projName, path: file.path, language: "python", dependencies: deps)
    }
}

public struct RubyParser: ManifestParser {
    public init() {}

    public func parse(_ file: URL) async -> Project? {
        guard file.lastPathComponent == "Gemfile",
              let content = try? String(contentsOf: file, encoding: .utf8)
        else { return nil }

        var deps: [ProjectDependency] = []
        let rubyPattern = #"ruby ['"](\d+\.\d+\.\d+)"#
        if let match = content.firstMatch(of: try! Regex(rubyPattern)),
           let ver = match.output[1].substring {
            deps.append(ProjectDependency(tool: "ruby", versionConstraint: String(ver)))
        }

        let projName = file.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent
        return Project(name: projName, path: file.path, language: "ruby", dependencies: deps)
    }
}

public struct CocoaPodsParser: ManifestParser {
    public init() {}

    public func parse(_ file: URL) async -> Project? {
        guard file.lastPathComponent == "Podfile",
              let content = try? String(contentsOf: file, encoding: .utf8)
        else { return nil }

        var deps: [ProjectDependency] = []
        let platformPattern = #"platform\s*:\w+,\s*['"](\d+\.\d+)"#
        if content.firstMatch(of: try! Regex(platformPattern)) != nil {
            deps.append(ProjectDependency(tool: "xcode", versionConstraint: nil))
        }

        let projName = file.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent
        return Project(name: projName, path: file.path, language: "swift", dependencies: deps)
    }
}

public struct ComposerParser: ManifestParser {
    public init() {}

    public func parse(_ file: URL) async -> Project? {
        guard file.lastPathComponent == "composer.json",
              let data = try? Data(contentsOf: file),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        let name = (json["name"] as? String) ?? file.deletingLastPathComponent().lastPathComponent
        var deps: [ProjectDependency] = []

        if let require = json["require"] as? [String: String],
           let phpVer = require["php"] {
            deps.append(ProjectDependency(tool: "php", versionConstraint: phpVer))
        }

        return Project(name: name, path: file.path, language: "php", dependencies: deps)
    }
}
