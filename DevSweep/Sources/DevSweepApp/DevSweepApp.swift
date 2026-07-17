import SwiftUI

@main
struct DevSweepApp: App {
    @State private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .frame(minWidth: 800, minHeight: 560)
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .appInfo) {
                Button("About DevSweep") {
                    NSApplication.shared.orderFrontStandardAboutPanel()
                }
            }
        }
    }
}
