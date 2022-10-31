import AlertBuilder
import Builder
import Encryption
import UIKit

public protocol LogViewerDependencies {
    associatedtype AlertBuilderType: AlertBuilder

    var alertBuilder: AlertBuilderType { get }
    var decryptionKey: String? { get }
    var logs: Data { get }
    var name: String? { get }
}

public struct LogViewerArgs {
    public let logs: Data
    public let name: String?

    public init(logs: Data, name: String?) {
        self.logs = logs
        self.name = name
    }
}

public struct LogViewerBuilder<LVD: LogViewerDependencies>: Builder {
    public init() { }

    public func build(using dependencies: LVD) -> UIViewController {
        let name = dependencies.name ?? "logs.kplogs"
        let nameWithoutExtension = name.replacing(".kplogs", with: "")

        let logFilesURLProvider = LogFilesURLProvider(name: name)

        let repository = LogEntriesRepository(
            logs: dependencies.logs,
            logFilesURLProvider: logFilesURLProvider,
            decryptionKey: dependencies.decryptionKey
        )

        let itemsProvider = LogsViewerItemsProvider(logFilesURLProvider: logFilesURLProvider)
        itemsProvider.dataSource = repository

        let viewController = LogsViewerViewController(
            name: nameWithoutExtension,
            repository: repository,
            itemsProvider: itemsProvider,
            alertBuilder: dependencies.alertBuilder
        )
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.isToolbarHidden = false

        return navigationController
    }
}
