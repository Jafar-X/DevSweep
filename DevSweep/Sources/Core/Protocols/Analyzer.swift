import Foundation

public protocol Analyzer: AnyObject, Sendable {
    var id: String { get }
    var name: String { get }
    var description: String { get }

    func scan() async throws -> AnalysisResult
}
