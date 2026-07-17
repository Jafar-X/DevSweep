import Foundation

public protocol StorageScanner: Sendable {
    func scan(paths: [URL]) async throws -> [StorageItem]
}

extension StorageScanner {
    /// Scans a single path if it exists on disk. Returns nil for missing or empty directories.
    public func scanIfExists(_ path: URL) async -> StorageItem? {
        guard FileManager.default.fileExists(atPath: path.path) else { return nil }
        guard let item = try? await scan(paths: [path]).first, item.fileCount > 0 else { return nil }
        return item
    }
}
