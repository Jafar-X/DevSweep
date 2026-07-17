import Foundation

public protocol Scanner: Sendable {
    func scan(paths: [URL]) async throws -> [StorageItem]
}
