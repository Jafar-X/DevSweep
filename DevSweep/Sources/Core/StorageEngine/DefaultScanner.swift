import Foundation

public final class DefaultScanner: StorageScanner, @unchecked Sendable {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func scan(paths: [URL]) async throws -> [StorageItem] {
        var items: [StorageItem] = []
        for path in paths {
            if let item = scanSingle(path: path) {
                items.append(item)
            }
        }
        return items
    }

    private func scanSingle(path: URL) -> StorageItem? {
        var totalBytes: Int64 = 0
        var fileCount = 0
        var latestModified: Date = .distantPast
        var latestAccessed: Date = .distantPast

        guard let enumerator = fileManager.enumerator(
            at: path,
            includingPropertiesForKeys: [
                .totalFileAllocatedSizeKey,
                .fileAllocatedSizeKey,
                .contentModificationDateKey,
                .contentAccessDateKey,
                .isDirectoryKey,
            ],
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { _, _ in true }
        ) else {
            return nil
        }

        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [
                .totalFileAllocatedSizeKey,
                .fileAllocatedSizeKey,
                .contentModificationDateKey,
                .contentAccessDateKey,
                .isDirectoryKey,
            ]) else {
                continue
            }

            if resourceValues.isDirectory == true {
                continue
            }

            let size = resourceValues.totalFileAllocatedSize
                ?? resourceValues.fileAllocatedSize
                ?? 0
            totalBytes += Int64(size)

            fileCount += 1

            if let mod = resourceValues.contentModificationDate, mod > latestModified {
                latestModified = mod
            }
            if let acc = resourceValues.contentAccessDate, acc > latestAccessed {
                latestAccessed = acc
            }
        }

        if latestModified == .distantPast { latestModified = Date() }
        if latestAccessed == .distantPast { latestAccessed = Date() }

        return StorageItem(
            path: path.path,
            sizeKB: Double(totalBytes) / 1024.0,
            sizeMB: Double(totalBytes) / 1_048_576.0,
            fileCount: fileCount,
            lastModified: latestModified,
            lastAccessed: latestAccessed
        )
    }
}
