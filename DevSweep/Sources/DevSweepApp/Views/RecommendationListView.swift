import SwiftUI
import Core

struct RecommendationListView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var filter: Verdict? = nil

    private var filtered: [Recommendation] {
        let sorted = viewModel.recommendations.sorted { $0.confidence > $1.confidence }
        guard let filter else { return sorted }
        return sorted.filter { $0.verdict == filter }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter bar
            HStack(spacing: 8) {
                FilterChip(label: "All", count: viewModel.recommendations.count, active: filter == nil) {
                    filter = nil
                }
                FilterChip(label: "Safe", count: countFor(.safeToRemove), active: filter == .safeToRemove) {
                    filter = .safeToRemove
                }
                FilterChip(label: "Consider", count: countFor(.considerRemoving), active: filter == .considerRemoving) {
                    filter = .considerRemoving
                }
                FilterChip(label: "Keep", count: countFor(.keep), active: filter == .keep) {
                    filter = .keep
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            if filtered.isEmpty {
                ContentUnavailableView("No recommendations", systemImage: "checkmark.circle", description: Text("Scan to see what can be cleaned up."))
            } else {
                List(filtered) { rec in
                    RecommendationRow(recommendation: rec)
                }
            }
        }
    }

    private func countFor(_ verdict: Verdict) -> Int {
        viewModel.recommendations.filter { $0.verdict == verdict }.count
    }
}

struct FilterChip: View {
    let label: String
    let count: Int
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(label)
                Text("\(count)")
                    .font(.caption2.monospacedDigit())
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(.quaternary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(active ? Color.accentColor : Color.clear)
            .foregroundStyle(active ? .white : .primary)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(.quaternary, lineWidth: active ? 0 : 1))
        }
        .buttonStyle(.plain)
    }
}

struct RecommendationRow: View {
    let recommendation: Recommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(shortPath(recommendation.itemPath))
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                ConfidenceBadge(score: recommendation.confidence)
            }

            if !recommendation.factors.isEmpty {
                Text(recommendation.factors.prefix(2).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }

    private func shortPath(_ path: String) -> String {
        let home = NSHomeDirectory()
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}
