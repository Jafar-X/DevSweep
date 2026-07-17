import Core
import Services

public final class Container: Sendable {
    public let logger: Logger
    public let pluginLoader: any PluginLoader
    public let scanner: any StorageScanner

    public init(
        logger: Logger,
        pluginLoader: any PluginLoader,
        scanner: any StorageScanner
    ) {
        self.logger = logger
        self.pluginLoader = pluginLoader
        self.scanner = scanner
    }

    public static func makeDefault() -> Container {
        let logger = Logger()
        let pluginLoader = DefaultPluginLoader()
        let scanner = DefaultScanner()
        return Container(
            logger: logger,
            pluginLoader: pluginLoader,
            scanner: scanner
        )
    }
}
