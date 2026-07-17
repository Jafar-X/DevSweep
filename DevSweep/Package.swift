// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "DevSweep",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "devsweep", targets: ["DevSweepCLI"]),
        .executable(name: "test-runner", targets: ["TestRunner"]),
        .executable(name: "DevSweep", targets: ["DevSweepApp"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "Core"),
        .target(name: "Services", dependencies: ["Core"]),
        .target(name: "Plugins", dependencies: ["Core", "Services"]),
        .target(
            name: "DevSweepKit",
            dependencies: ["Core", "Services", "Plugins"]
        ),
        .executableTarget(
            name: "DevSweepCLI",
            dependencies: ["DevSweepKit"]
        ),
        .executableTarget(
            name: "TestRunner",
            dependencies: ["DevSweepKit"]
        ),
        .executableTarget(
            name: "DevSweepApp",
            dependencies: ["DevSweepKit"]
        ),
    ]
)
