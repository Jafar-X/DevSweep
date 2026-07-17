import Foundation
import Core
import Services

public final class DockerAnalyzer: Analyzer, @unchecked Sendable {
    public let id = "docker"
    public let name = "Docker"
    public let description = "Scans Docker images, containers, volumes, and build cache."

    private let logger: Logger
    private let scanner: any StorageScanner

    public init(logger: Logger, scanner: any StorageScanner) {
        self.logger = logger
        self.scanner = scanner
    }

    public func scan() async throws -> AnalysisResult {
        guard let dockerPath = findDocker() else {
            logger.info("Docker not installed — skipping")
            return emptyResult()
        }

        var items: [StorageItem] = []

        // docker system df (total overview)
        let dfOutput = await runDocker(dockerPath, ["system", "df"])
        if !dfOutput.isEmpty {
            let parsed = parseDockerDF(dfOutput)
            for entry in parsed {
                items.append(entry)
            }
        }

        // Docker data directory
        let dockerDataPaths: [URL] = [
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Containers/com.docker.docker/Data"),
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".colima"),
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".orbstack"),
        ]
        for path in dockerDataPaths {
            if let item = await scanner.scanIfExists(path) { items.append(item) }
        }

        let totalKB = items.reduce(0) { $0 + $1.sizeKB }
        let totalMB = items.reduce(0) { $0 + $1.sizeMB }

        if items.isEmpty {
            logger.info("Docker: no data found")
        } else {
            logger.info("Docker: \(items.count) location(s), \(String(format: "%.1f", totalMB)) MB")
        }

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

    private func findDocker() -> URL? {
        for path in ["/opt/homebrew/bin/docker", "/usr/local/bin/docker"] {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.isExecutableFile(atPath: url.path) { return url }
        }
        return nil
    }

    private func runDocker(_ docker: URL, _ args: [String]) async -> String {
        await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = docker
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

    /// Parses `docker system df` output into StorageItems.
    /// Typical output lines: "Images\t3\t5\t1.2GB\t1.2GB (100%)"
    private func parseDockerDF(_ raw: String) -> [StorageItem] {
        let lines = raw.split(separator: "\n")
        guard lines.count > 1 else { return [] }

        var items: [StorageItem] = []
        for line in lines.dropFirst() {
            let cols = line.split(separator: "\t").map { String($0) }
            guard cols.count >= 3 else { continue }
            let kind = cols[0].trimmingCharacters(in: .whitespaces)
            let sizeStr = cols[2]
            let sizeMB = parseSize(sizeStr)
            items.append(
                StorageItem(
                    path: "docker://\(kind.lowercased())",
                    sizeKB: sizeMB * 1024.0,
                    sizeMB: sizeMB,
                    fileCount: Int(cols[1]) ?? 0,
                    lastModified: Date(),
                    lastAccessed: Date()
                )
            )
        }
        return items
    }

    private func parseSize(_ s: String) -> Double {
        let cleaned = s.uppercased().trimmingCharacters(in: .whitespaces)
        if cleaned.hasSuffix("GB") {
            return (Double(cleaned.dropLast(2)) ?? 0) * 1000.0
        } else if cleaned.hasSuffix("MB") {
            return Double(cleaned.dropLast(2)) ?? 0
        } else if cleaned.hasSuffix("KB") {
            return (Double(cleaned.dropLast(2)) ?? 0) / 1000.0
        }
        return 0
    }

    private func emptyResult() -> AnalysisResult {
        AnalysisResult(
            analyzerId: id, analyzerName: name,
            items: [], totalSizeKB: 0, totalSizeMB: 0, itemCount: 0, errors: []
        )
    }
}
