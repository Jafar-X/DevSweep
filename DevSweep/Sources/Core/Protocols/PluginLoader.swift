public protocol PluginLoader: Sendable {
    func loadAll() -> [any Analyzer]
}
