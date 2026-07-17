public final class DefaultPluginLoader: PluginLoader, Sendable {
    public init() {}

    public func loadAll() -> [any Analyzer] {
        AnalyzerRegistry.all
    }
}
