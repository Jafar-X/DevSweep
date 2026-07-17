import SwiftUI

struct ContentView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var selectedTab: Tab = .dashboard

    enum Tab: String, CaseIterable, Hashable {
        case dashboard = "Dashboard"
        case recommendations = "Recommendations"

        var icon: String {
            switch self {
            case .dashboard: "square.grid.2x2"
            case .recommendations: "list.bullet.clipboard"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Section("Overview") {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon)
                            .tag(tab)
                    }
                }

                Section("Analyzers") {
                    ForEach(viewModel.results, id: \.analyzerId) { result in
                        Label(result.analyzerName, systemImage: iconFor(result.analyzerId))
                            .tag(Tab.dashboard)  // handled in detail
                            .badge(formatSize(result.totalSizeMB))
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            switch selectedTab {
            case .dashboard:
                DashboardView()
            case .recommendations:
                RecommendationListView()
            }
        }
        .task {
            await viewModel.refresh()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { Task { await viewModel.refresh() } }) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isScanning)
                .help("Refresh scan")
            }
        }
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
        case "dummy": "questionmark"
        default: "square"
        }
    }

    private func formatSize(_ mb: Double) -> String {
        if mb >= 1000 { String(format: "%.1fG", mb / 1024) }
        else if mb >= 1 { String(format: "%.0fM", mb) }
        else { "<1M" }
    }
}
