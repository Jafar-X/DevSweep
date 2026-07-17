import Foundation

public struct Project: Codable, Sendable, Identifiable {
    public var id: String { path }

    public let name: String
    public let path: String
    public let language: String
    public let dependencies: [ProjectDependency]

    public init(name: String, path: String, language: String, dependencies: [ProjectDependency]) {
        self.name = name
        self.path = path
        self.language = language
        self.dependencies = dependencies
    }
}

public struct ProjectDependency: Codable, Sendable {
    public let tool: String
    public let versionConstraint: String?

    public init(tool: String, versionConstraint: String?) {
        self.tool = tool
        self.versionConstraint = versionConstraint
    }
}
