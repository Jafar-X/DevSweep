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
        var hasVeto = false

        for factor in factors {
            switch factor.assess(item: item, context: context) {
            case .safe(let reason):
                safeReasons.append("[\(factor.name)] \(reason)")
            case .keep(let reason):
                keepReasons.append("[\(factor.name)] \(reason)")
                if factor.isVeto {
                    hasVeto = true
                }
            case .neutral:
                break
            }
        }

        // Veto factors (RunningProcess, SystemComponent) force "keep" regardless.
        if hasVeto {
            return Recommendation(
                itemPath: item.path,
                verdict: .keep,
                confidence: max(10, 100 - keepReasons.count * 15),
                factors: safeReasons,
                conflictingFactors: keepReasons
            )
        }

        let safeCount = safeReasons.count
        let keepCount = keepReasons.count
        let total = safeCount + keepCount

        let safetyRatio = total > 0 ? Double(safeCount) / Double(total) : 0.5
        let baseConfidence = Int(safetyRatio * 100)
        let agreementBonus = min(total * 5, 20)
        var confidence = min(baseConfidence + agreementBonus, 100)

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
