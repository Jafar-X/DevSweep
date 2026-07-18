import SwiftUI

struct ContentView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var selectedItem: SidebarItem? = .dashboard

    enum SidebarItem: Hashable {
        case dashboard
        case recommendations
        case analyzer(id: String)
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedItem) {
                Section("Overview") {
                    NavigationLink(value: SidebarItem.dashboard) {
                        Label("Dashboard", systemImage: "square.grid.2x2")
                    }
                    NavigationLink(value: SidebarItem.recommendations) {
                        Label("Recommendations", systemImage: "list.bullet.clipboard")
                    }
                }

                Section("Analyzers") {
                    ForEach(viewModel.results, id: \.analyzerId) { result in
                        NavigationLink(value: SidebarItem.analyzer(id: result.analyzerId)) {
                            Label(result.analyzerName, systemImage: iconFor(result.analyzerId))
                                .badge(formatSize(result.totalSizeMB))
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            switch selectedItem {
            case .dashboard, nil:
                DashboardView()
            case .recommendations:
                RecommendationListView()
            case .analyzer(let id):
                if let result = viewModel.results(for: id) {
                    AnalyzerDetailView(result: result)
                } else {
                    ContentUnavailableView("Not found", systemImage: "questionmark")
                }
            }
        }
        .task { await viewModel.refresh() }
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
        case "junk": "trash"
        default: "square"
        }
    }

    private func formatSize(_ mb: Double) -> String {
        if mb >= 1000 { String(format: "%.1fG", mb / 1024) }
        else if mb >= 1 { String(format: "%.0fM", mb) }
        else { "<1M" }
    }
}
