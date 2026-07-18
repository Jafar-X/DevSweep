import Foundation

/// Context available to all risk factors.
public struct RiskContext: Sendable {
    public let dependencyGraph: DependencyGraph?
    public let runningProcessPaths: Set<String>

    public init(dependencyGraph: DependencyGraph?, runningProcessPaths: Set<String>) {
        self.dependencyGraph = dependencyGraph
        self.runningProcessPaths = runningProcessPaths
    }
}

public enum RiskImpact: Sendable {
    /// Evidence suggests this item CAN be removed safely.
    case safe(reason: String)
    /// Evidence suggests this item should NOT be removed.
    case keep(reason: String)
    /// Cannot determine — neutral impact.
    case neutral
}

public protocol RiskFactor: Sendable {
    var name: String { get }
    /// If true, a `.keep` from this factor overrides all other factors.
    var isVeto: Bool { get }
    func assess(item: StorageItem, context: RiskContext) -> RiskImpact
}

public extension RiskFactor {
    var isVeto: Bool { false }
}
