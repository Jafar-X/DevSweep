import Foundation

public final class DefaultScanner: Scanner, @unchecked Sendable {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func scan(paths: [URL]) async throws -> [StorageItem] {
        []
    }
}
