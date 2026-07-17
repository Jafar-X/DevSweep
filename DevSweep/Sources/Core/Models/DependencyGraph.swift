import Foundation

/// Connects projects to the tools they depend on.
/// Answers "What uses Java 17?" and "Which tools are orphaned?"
public struct DependencyGraph: Codable, Sendable {
    public let projects: [Project]

    public init(projects: [Project]) {
        self.projects = projects
    }

    /// All projects that depend on a given tool.
    public func projectsUsing(tool: String) -> [Project] {
        projects.filter { project in
            project.dependencies.contains { dep in
                dep.tool.caseInsensitiveCompare(tool) == .orderedSame
            }
        }
    }

    /// Tools from known analyzers that have zero project references.
    public func unusedTools(knownToolIds: Set<String>) -> Set<String> {
        let referenced = Set(
            projects.flatMap(\.dependencies).map { $0.tool.lowercased() }
        )
        return knownToolIds.filter { tool in
            !referenced.contains(tool.lowercased())
        }
    }
}
