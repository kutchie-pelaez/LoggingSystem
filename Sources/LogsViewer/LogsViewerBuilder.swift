import Builder
import LogEntryEncryption
import UIKit

public protocol LogViewerBuilderDependencies {
    var logs: Data { get }
    var decryptionKey: String? { get }
}

public struct LogViewerBuilder: Builder {
    public func build(using dependencies: LogViewerBuilderDependencies) -> UIViewController {
        let logEntryDecryptor = dependencies.decryptionKey.map(LogEntryDecryptor.init)
        let repository = LogEntriesRepository(logs: dependencies.logs, logEntryDecryptor: logEntryDecryptor)
        let viewController = LogsViewerViewController(repository: repository)

        return viewController
    }
}
