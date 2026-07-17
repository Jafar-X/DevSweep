import Foundation
import Core
import Services

public final class AndroidAnalyzer: Analyzer, @unchecked Sendable {
    public let id = "android"
    public let name = "Android"
    public let description = "Scans Android SDK, NDK, emulators, and Gradle cache."

    private let logger: Logger
    private let scanner: any StorageScanner

    public init(logger: Logger, scanner: any StorageScanner) {
        self.logger = logger
        self.scanner = scanner
    }

    public func scan() async throws -> AnalysisResult {
        let home = FileManager.default.homeDirectoryForCurrentUser
        var items: [StorageItem] = []

        // Android SDK
        let sdkRoot = ProcessInfo.processInfo.environment["ANDROID_HOME"]
            ?? home.appendingPathComponent("Library/Android/sdk").path
        let sdkURL = URL(fileURLWithPath: sdkRoot)

        let sdkSubPaths: [String] = [
            "platforms", "build-tools", "ndk", "system-images",
            "emulator", "platform-tools", "cmake",
        ]
        for sub in sdkSubPaths {
            if let item = await scanner.scanIfExists(
                sdkURL.appendingPathComponent(sub)
            ) { items.append(item) }
        }

        // Gradle cache
        if let item = await scanner.scanIfExists(
            home.appendingPathComponent(".gradle/caches")
        ) { items.append(item) }

        // AVDs (emulator images)
        if let item = await scanner.scanIfExists(
            home.appendingPathComponent(".android/avd")
        ) { items.append(item) }

        let totalKB = items.reduce(0) { $0 + $1.sizeKB }
        let totalMB = items.reduce(0) { $0 + $1.sizeMB }

        if items.isEmpty {
            logger.info("Android: no SDK or caches found")
        } else {
            logger.info("Android: \(items.count) location(s), \(String(format: "%.1f", totalMB)) MB")
        }

        return AnalysisResult(
            analyzerId: id, analyzerName: name,
            items: items, totalSizeKB: totalKB, totalSizeMB: totalMB,
            itemCount: items.count, errors: []
        )
    }
}
