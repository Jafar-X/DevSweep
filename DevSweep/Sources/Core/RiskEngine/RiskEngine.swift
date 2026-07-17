import Foundation

/// Aggregates risk factors to produce confidence-scored recommendations.
public struct RiskEngine: Sendable {
    private let factors: [any RiskFactor]

    public init(factors: [any RiskFactor]) {
        self.factors = factors
    }

    /// Produce recommendations for every StorageItem across all analysis results.
    public func evaluate(
        results: [AnalysisResult],
        context: RiskContext
    ) -> [Recommendation] {
        var recommendations: [Recommendation] = []

        for result in results {
            for item in result.items {
                let rec = evaluateSingle(item: item, context: context)
                recommendations.append(rec)
            }
        }

        return recommendations.sorted { $0.confidence > $1.confidence }
    }

    private func evaluateSingle(item: StorageItem, context: RiskContext) -> Recommendation {
        var safeReasons: [String] = []
        var keepReasons: [String] = []

        for factor in factors {
            switch factor.assess(item: item, context: context) {
            case .safe(let reason):
                safeReasons.append("[\(factor.name)] \(reason)")
            case .keep(let reason):
                keepReasons.append("[\(factor.name)] \(reason)")
            case .neutral:
                break
            }
        }

        let safeCount = safeReasons.count
        let keepCount = keepReasons.count
        let total = safeCount + keepCount

        // Confidence: proportion of factors that agree, scaled to 0..100.
        // Factors for removal raise confidence; factors against lower it.
        let safetyRatio = total > 0 ? Double(safeCount) / Double(total) : 0.5
        let baseConfidence = Int(safetyRatio * 100)

        // Boost confidence when multiple factors agree
        let agreementBonus = min(total * 5, 20)
        var confidence = min(baseConfidence + agreementBonus, 100)

        // Penalize if keep reasons exist
        if keepCount > 0 {
            confidence = max(confidence - keepCount * 10, 10)
        }

        let verdict: Verdict
        switch confidence {
        case 80...100: verdict = .safeToRemove
        case 60..<80:  verdict = .considerRemoving
        case 40..<60:  verdict = .considerRemoving
        default:        verdict = .keep
        }

        return Recommendation(
            itemPath: item.path,
            verdict: verdict,
            confidence: confidence,
            factors: safeReasons,
            conflictingFactors: keepReasons
        )
    }
}
