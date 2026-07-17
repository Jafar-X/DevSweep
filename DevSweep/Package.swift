// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "DevSweep",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "devsweep", targets: ["DevSweepCLI"]),
        .executable(name: "test-runner", targets: ["TestRunner"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "Core"),
        .target(name: "Services", dependencies: ["Core"]),
        .target(name: "Plugins", dependencies: ["Core", "Services"]),
        .executableTarget(
            name: "DevSweepCLI",
            dependencies: ["Core", "Services", "Plugins"]
        ),
        .executableTarget(
            name: "TestRunner",
            dependencies: ["Core", "Services", "Plugins"]
        ),
        // Uncomment when Xcode is installed (XCTest/Swift Testing frameworks not in CLT):
        // .testTarget(name: "CoreTests", dependencies: ["Core"]),
        // .testTarget(name: "PluginTests", dependencies: ["Plugins", "Core"]),
    ]
)
