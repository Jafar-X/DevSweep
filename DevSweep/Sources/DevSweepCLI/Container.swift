import Core
import Services

public final class Container: Sendable {
    public let logger: Logger
    public let pluginLoader: any PluginLoader
    public let scanner: any StorageScanner
    public let projectDiscovery: ProjectDiscovery
    public let manifestParser: ManifestParserRegistry

    public init(
        logger: Logger,
        pluginLoader: any PluginLoader,
        scanner: any StorageScanner,
        projectDiscovery: ProjectDiscovery,
        manifestParser: ManifestParserRegistry
    ) {
        self.logger = logger
        self.pluginLoader = pluginLoader
        self.scanner = scanner
        self.projectDiscovery = projectDiscovery
        self.manifestParser = manifestParser
    }

    public static func makeDefault() -> Container {
        let logger = Logger()
        let pluginLoader = DefaultPluginLoader()
        let scanner = DefaultScanner()
        let projectDiscovery = ProjectDiscovery()
        let manifestParser = ManifestParserRegistry(parsers: [
            NodePackageParser(),
            MavenParser(),
            GradleParser(),
            CargoParser(),
            GoModParser(),
            PythonManifestParser(),
            RubyParser(),
            CocoaPodsParser(),
            ComposerParser(),
        ])
        return Container(
            logger: logger,
            pluginLoader: pluginLoader,
            scanner: scanner,
            projectDiscovery: projectDiscovery,
            manifestParser: manifestParser
        )
    }
}
