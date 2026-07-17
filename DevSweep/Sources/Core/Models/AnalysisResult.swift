import Foundation

public struct AnalysisResult: Codable, Sendable {
    public let analyzerId: String
    public let analyzerName: String
    public let items: [StorageItem]
    public let totalSizeKB: Double
    public let totalSizeMB: Double
    public let itemCount: Int
    public let errors: [String]

    public init(
        analyzerId: String,
        analyzerName: String,
        items: [StorageItem],
        totalSizeKB: Double,
        totalSizeMB: Double,
        itemCount: Int,
        errors: [String]
    ) {
        self.analyzerId = analyzerId
        self.analyzerName = analyzerName
        self.items = items
        self.totalSizeKB = totalSizeKB
        self.totalSizeMB = totalSizeMB
        self.itemCount = itemCount
        self.errors = errors
    }
}
