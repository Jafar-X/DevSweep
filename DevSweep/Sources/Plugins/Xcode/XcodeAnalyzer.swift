import Foundation
import Core
import Services

public final class XcodeAnalyzer: Analyzer, @unchecked Sendable {
    public let id = "xcode"
    public let name = "Xcode"
    public let description = "Scans Xcode caches, derived data, simulators, and archives."

    private let logger: Logger
    private let scanner: any StorageScanner

    public init(logger: Logger, scanner: any StorageScanner) {
        self.logger = logger
        self.scanner = scanner
    }

    public func scan() async throws -> AnalysisResult {
        let home = FileManager.default.homeDirectoryForCurrentUser
        var items: [StorageItem] = []

        let paths: [URL] = [
            home.appendingPathComponent("Library/Developer/Xcode/DerivedData"),
            home.appendingPathComponent("Library/Developer/Xcode/Archives"),
            home.appendingPathComponent("Library/Developer/Xcode/iOS DeviceSupport"),
            home.appendingPathComponent("Library/Developer/CoreSimulator/Devices"),
            home.appendingPathComponent("Library/Caches/org.swift.swiftpm"),
        ]

        for path in paths {
            if let item = await scanner.scanIfExists(path) { items.append(item) }
        }

        // Detect installed Xcode versions
        let xcodeApps = detectXcodeVersions()
        if !xcodeApps.isEmpty {
            items.append(
                StorageItem(
                    path: "/Applications/Xcode",
                    sizeKB: 0,
                    sizeMB: 0,
                    fileCount: xcodeApps.count,
                    lastModified: Date(),
                    lastAccessed: Date()
                )
            )
        }

        let totalKB = items.reduce(0) { $0 + $1.sizeKB }
        let totalMB = items.reduce(0) { $0 + $1.sizeMB }

        if items.isEmpty {
            logger.info("Xcode: no data found")
        } else {
            logger.info("Xcode: \(items.count) location(s) including \(xcodeApps.count) Xcode(s), \(String(format: "%.1f", totalMB)) MB")
        }

        return AnalysisResult(
            analyzerId: id, analyzerName: name,
            items: items, totalSizeKB: totalKB, totalSizeMB: totalMB,
            itemCount: items.count, errors: []
        )
    }

    private func detectXcodeVersions() -> [String] {
        let appsDir = URL(fileURLWithPath: "/Applications")
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: appsDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles
        ) else { return [] }
        return contents
            .filter { $0.lastPathComponent.lowercased().contains("xcode") }
            .map { $0.lastPathComponent }
    }
}
