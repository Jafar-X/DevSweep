import SwiftUI
import Core

struct AnalyzerDetailView: View {
    @Environment(AppViewModel.self) private var viewModel

    let result: AnalysisResult

    private var itemsWithRecs: [(StorageItem, Recommendation?)] {
        viewModel.recommendations(for: result.analyzerId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.analyzerName)
                        .font(.title2.bold())
                    if result.itemCount > 0 {
                        Text("\(result.itemCount) location(s)")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(formatMB(result.totalSizeMB))
                    .font(.title2.monospacedDigit().bold())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider().padding(.horizontal)

            if itemsWithRecs.isEmpty {
                ContentUnavailableView(
                    "No items",
                    systemImage: "folder",
                    description: Text("This analyzer found no data on your system.")
                )
            } else {
                List(itemsWithRecs, id: \.0.id) { (item, rec) in
                    AnalyzerItemRow(item: item, recommendation: rec)
                }
                .listStyle(.plain)
            }
        }
    }

    private func formatMB(_ mb: Double) -> String {
        if mb >= 1024 { String(format: "%.1f GB", mb / 1024) }
        else if mb >= 1 { String(format: "%.0f MB", mb) }
        else { "<1 MB" }
    }
}

// MARK: - Item Row

struct AnalyzerItemRow: View {
    let item: StorageItem
    let recommendation: Recommendation?

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack(spacing: 10) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 12)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(shortPath(item.path))
                            .font(.body)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Text("Modified \(item.lastModified.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(formatMB(item.sizeMB))
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.secondary)

                    if let rec = recommendation {
                        ConfidenceBadge(score: rec.confidence)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded, let rec = recommendation {
                Divider().padding(.leading, 30)
                VStack(alignment: .leading, spacing: 4) {
                    if !rec.factors.isEmpty {
                        ForEach(rec.factors, id: \.self) { reason in
                            HStack(alignment: .top, spacing: 4) {
                                Text("+").foregroundStyle(.green).font(.caption.monospacedDigit())
                                Text(reason)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    if !rec.conflictingFactors.isEmpty {
                        ForEach(rec.conflictingFactors, id: \.self) { reason in
                            HStack(alignment: .top, spacing: 4) {
                                Text("-").foregroundStyle(.red).font(.caption.monospacedDigit())
                                Text(reason)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    if rec.factors.isEmpty && rec.conflictingFactors.isEmpty {
                        Text("No risk data available — run a scan first.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.leading, 30)
                .padding(.vertical, 6)
                .padding(.trailing, 8)
            }
        }
    }

    private func shortPath(_ path: String) -> String {
        let home = NSHomeDirectory()
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }

    private func formatMB(_ mb: Double) -> String {
        if mb >= 1024 { String(format: "%.1f GB", mb / 1024) }
        else { String(format: "%.0f MB", mb) }
    }
}
