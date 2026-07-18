import Foundation

/// Collects paths currently in use by running processes.
public struct ProcessScanner: Sendable {
    public init() {}

    /// Returns the set of filesystem paths referenced in running process command lines.
    /// Fast — just parses `ps` output, no per-process lsof.
    public func runningProcessPaths() -> Set<String> {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-eo", "args="]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do { try process.run() } catch { return [] }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let output = String(data: data, encoding: .utf8) ?? ""
        var paths = Set<String>()

        for line in output.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("-") else { continue }

            let tokens = trimmed.split(separator: " ").map(String.init)
            for token in tokens {
                if token.hasPrefix("/") {
                    // Expand to parent directories so we can match against StorageItems
                    let url = URL(fileURLWithPath: token)
                    var current: URL = url
                    for _ in 0..<3 {
                        paths.insert(current.path)
                        current = current.deletingLastPathComponent()
                    }
                } else if token.hasPrefix("~/") {
                    let expanded = NSString(string: token).expandingTildeInPath
                    paths.insert(expanded)
                }
            }
        }

        return paths
    }
}
