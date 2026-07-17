import Foundation

public enum Verdict: String, Codable, Sendable {
    case keep
    case considerRemoving
    case safeToRemove
}

public struct Recommendation: Codable, Sendable, Identifiable {
    public var id: String { itemPath }

    public let itemPath: String
    public let verdict: Verdict
    public let confidence: Int
    public let factors: [String]
    public let conflictingFactors: [String]

    public init(
        itemPath: String,
        verdict: Verdict,
        confidence: Int,
        factors: [String],
        conflictingFactors: [String]
    ) {
        self.itemPath = itemPath
        self.verdict = verdict
        self.confidence = confidence
        self.factors = factors
        self.conflictingFactors = conflictingFactors
    }
}
