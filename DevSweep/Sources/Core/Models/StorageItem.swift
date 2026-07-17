import Foundation

public struct StorageItem: Codable, Sendable, Identifiable {
    public var id: String { path }

    public let path: String
    public let sizeKB: Double
    public let sizeMB: Double
    public let fileCount: Int
    public let lastModified: Date
    public let lastAccessed: Date

    public init(
        path: String,
        sizeKB: Double,
        sizeMB: Double,
        fileCount: Int,
        lastModified: Date,
        lastAccessed: Date
    ) {
        self.path = path
        self.sizeKB = sizeKB
        self.sizeMB = sizeMB
        self.fileCount = fileCount
        self.lastModified = lastModified
        self.lastAccessed = lastAccessed
    }
}
