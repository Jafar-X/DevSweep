import Foundation
import Core
import Services

public final class HomebrewAnalyzer: Analyzer, @unchecked Sendable {
    public let id = "homebrew"
    public let name = "Homebrew"
    public let description = "Scans Homebrew formulae, casks, and services."

    private let logger: Logger
    private let scanner: any StorageScanner

    public init(logger: Logger, scanner: any StorageScanner) {
        self.logger = logger
        self.scanner = scanner
    }

    public func scan() async throws -> AnalysisResult {
        guard let brewPath = findBrew() else {
            logger.info("Homebrew not installed — skipping")
            return emptyResult()
        }

        let brewPrefix = brewPath
            .deletingLastPathComponent()  // bin
            .deletingLastPathComponent()  // Homebrew prefix

        async let infoJSON = runBrew(brewPath, ["info", "--json=v2", "--installed"])
        async let servicesOutput = runBrew(brewPath, ["services", "list"])

        let packageNames = parseBrewInfo(await infoJSON)
        let runningServices = parseRunningServices(await servicesOutput)

        // Scan each formula/cask directory for accurate per-package sizes
        var items: [StorageItem] = []
        let fm = FileManager.default
        let cellarDir = brewPrefix.appendingPathComponent("Cellar")
        let caskDir = brewPrefix.appendingPathComponent("Caskroom")

        for name in packageNames {
            let cellarPkg = cellarDir.appendingPathComponent(name)
            let caskPkg = caskDir.appendingPathComponent(name)

            if fm.fileExists(atPath: cellarPkg.path),
               let scanned = try? await scanner.scan(paths: [cellarPkg]).first {
                items.append(StorageItem(
                    path: cellarPkg.path,
                    sizeKB: scanned.sizeKB,
                    sizeMB: scanned.sizeMB,
                    fileCount: scanned.fileCount,
                    lastModified: scanned.lastModified,
                    lastAccessed: scanned.lastAccessed
                ))
            } else if fm.fileExists(atPath: caskPkg.path),
                      let scanned = try? await scanner.scan(paths: [caskPkg]).first {
                items.append(StorageItem(
                    path: caskPkg.path,
                    sizeKB: scanned.sizeKB,
                    sizeMB: scanned.sizeMB,
                    fileCount: scanned.fileCount,
                    lastModified: scanned.lastModified,
                    lastAccessed: scanned.lastAccessed
                ))
            } else {
                // Some packages exist in brew info but not as Cellar dirs (e.g. virtual packages)
                items.append(StorageItem(
                    path: "homebrew://\(name)",
                    sizeKB: 0, sizeMB: 0, fileCount: 0,
                    lastModified: Date(), lastAccessed: Date()
                ))
            }
        }

        let totalKB = items.reduce(0) { $0 + $1.sizeKB }
        let totalMB = items.reduce(0) { $0 + $1.sizeMB }

        logger.info(
            "Homebrew: \(items.count) packages, \(runningServices) running services"
        )

        return AnalysisResult(
            analyzerId: id,
            analyzerName: name,
            items: items,
            totalSizeKB: totalKB,
            totalSizeMB: totalMB,
            itemCount: items.count,
            errors: []
        )
    }

    // MARK: - Private

    private func findBrew() -> URL? {
        for path in ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"] {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.isExecutableFile(atPath: url.path) { return url }
        }
        return nil
    }

    private func runBrew(_ brew: URL, _ args: [String]) async -> String {
        await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = brew
            process.arguments = args

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice

            do { try process.run() } catch {
                continuation.resume(returning: "")
                return
            }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            continuation.resume(returning: String(data: data, encoding: .utf8) ?? "")
        }
    }

    private func parseLines(_ raw: String) -> [String] {
        raw.split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func parseRunningServices(_ raw: String) -> Int {
        parseLines(raw).filter { $0.hasPrefix("started") || $0.contains("started") }.count
    }

    /// Returns just the package names (both formulae and casks) from brew info JSON.
    private func parseBrewInfo(_ raw: String) -> [String] {
        guard let data = raw.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return [] }

        var names: [String] = []

        if let formulae = json["formulae"] as? [[String: Any]] {
            names += formulae.compactMap { $0["name"] as? String }
        }
        if let casks = json["casks"] as? [[String: Any]] {
            names += casks.compactMap { ($0["token"] as? String) ?? ($0["name"] as? String) }
        }

        return names
    }

    private func emptyResult() -> AnalysisResult {
        AnalysisResult(
            analyzerId: id, analyzerName: name,
            items: [], totalSizeKB: 0, totalSizeMB: 0, itemCount: 0, errors: []
        )
    }
}
