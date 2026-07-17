import SwiftUI
import Core

struct DashboardView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("Developer Storage")
                        .font(.title2.bold())
                    Spacer()
                    if viewModel.isScanning {
                        ProgressView().scaleEffect(0.8)
                    } else if let date = viewModel.lastScanDate {
                        Text("Last scan: \(date.formatted(.relative(presentation: .numeric)))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Summary cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 12) {
                    StatCard(
                        title: "Total Storage",
                        value: formatMB(viewModel.totalStorageMB),
                        color: .blue
                    )
                    StatCard(
                        title: "Recoverable",
                        value: formatMB(viewModel.potentiallyRecoverableMB),
                        color: .green
                    )
                    StatCard(
                        title: "Analyzed",
                        value: "\(viewModel.analyzerCount)",
                        color: .orange
                    )
                }

                Divider()

                // Per-analyzer breakdown
                Text("By Ecosystem")
                    .font(.headline)

                let sorted = viewModel.results
                    .filter { $0.totalSizeMB > 0 }
                    .sorted { $0.totalSizeMB > $1.totalSizeMB }

                ForEach(sorted, id: \.analyzerId) { result in
                    AnalyzerRow(result: result)
                }
            }
            .padding()
        }
    }

    private func formatMB(_ mb: Double) -> String {
        if mb >= 1024 { String(format: "%.1f GB", mb / 1024) }
        else if mb >= 1 { String(format: "%.0f MB", mb) }
        else { "<1 MB" }
    }
}

// MARK: - Subviews

struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.monospacedDigit().bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct AnalyzerRow: View {
    let result: AnalysisResult

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconFor(result.analyzerId))
                .frame(width: 24)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading) {
                Text(result.analyzerName)
                    .font(.body)
                if result.itemCount > 0 {
                    Text("\(result.itemCount) location(s)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(formatMB(result.totalSizeMB))
                .font(.body.monospacedDigit().bold())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func iconFor(_ id: String) -> String {
        switch id {
        case "homebrew": "mug"
        case "java": "cup.and.saucer"
        case "node": "arrow.triangle.branch"
        case "python": "snake"
        case "docker": "shippingbox"
        case "xcode": "hammer"
        case "android": "rectangle.portrait.and.arrow.right"
        case "git": "arrow.triangle.pull"
        case "projects": "folder"
        default: "square"
        }
    }

    private func formatMB(_ mb: Double) -> String {
        if mb >= 1024 { String(format: "%.1f GB", mb / 1024) }
        else { String(format: "%.0f MB", mb) }
    }
}
