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

        async let formulae = runBrew(brewPath, ["list", "--formula"])
        async let casks = runBrew(brewPath, ["list", "--cask"])
        async let servicesOutput = runBrew(brewPath, ["services", "list"])
        async let infoJSON = runBrew(brewPath, ["info", "--json=v2", "--installed"])

        let formulaList = parseLines(await formulae)
        let caskList = parseLines(await casks)
        let runningServices = parseRunningServices(await servicesOutput)
        _ = parseBrewInfo(await infoJSON)

        // Scan brew prefix for total storage
        let brewPrefix = brewPath
            .deletingLastPathComponent()  // bin
            .deletingLastPathComponent()  // brew path
        let scannedItems = try? await scanner.scan(paths: [brewPrefix])
        let allItems: [StorageItem] = scannedItems ?? []

        let totalKB = allItems.reduce(0) { $0 + $1.sizeKB }
        let totalMB = allItems.reduce(0) { $0 + $1.sizeMB }

        logger.info(
            "Homebrew: \(formulaList.count) formulae, \(caskList.count) casks, \(runningServices) running services"
        )

        return AnalysisResult(
            analyzerId: id,
            analyzerName: name,
            items: allItems,
            totalSizeKB: totalKB,
            totalSizeMB: totalMB,
            itemCount: formulaList.count + caskList.count,
            errors: []
        )
    }

    // MARK: - Private

    private func findBrew() -> URL? {
        let candidates = [
            "/opt/homebrew/bin/brew",
            "/usr/local/bin/brew",
        ]
        for path in candidates {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.isExecutableFile(atPath: url.path) {
                return url
            }
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

            do {
                try process.run()
            } catch {
                continuation.resume(returning: "")
                return
            }

            // Read concurrently so the pipe buffer doesn't fill and deadlock.
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()

            let output = String(data: data, encoding: .utf8) ?? ""
            continuation.resume(returning: output)
        }
    }

    private func parseLines(_ raw: String) -> [String] {
        raw.split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func parseRunningServices(_ raw: String) -> Int {
        parseLines(raw)
            .filter { $0.hasPrefix("started") || $0.contains("started") }
            .count
    }

    private func parseBrewInfo(_ raw: String) -> [(name: String, sizeKB: Double)] {
        guard let data = raw.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let formulae = json["formulae"] as? [[String: Any]]
        else {
            return []
        }

        return formulae.compactMap { formula in
            guard let name = formula["name"] as? String else { return nil }
            let installInfo = formula["installed"] as? [[String: Any]]
            let totalBytes = installInfo?.compactMap {
                ($0["size_in_bytes"] as? Int64) ?? ($0["size"] as? Int64)
            }.reduce(0, +) ?? 0
            return (name, Double(totalBytes) / 1024.0)
        }
    }

    private func emptyResult() -> AnalysisResult {
        AnalysisResult(
            analyzerId: id,
            analyzerName: name,
            items: [],
            totalSizeKB: 0,
            totalSizeMB: 0,
            itemCount: 0,
            errors: []
        )
    }
}
