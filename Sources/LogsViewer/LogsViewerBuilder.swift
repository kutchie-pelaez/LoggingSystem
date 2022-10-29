import Builder
import LogEntryEncryption
import UIKit

public protocol LogViewerDependencies {
    var logs: Data { get }
    var decryptionKey: String? { get }
}

public struct LogViewerArgs {
    public let logs: Data

    public init(logs: Data) {
        self.logs = logs
    }
}

public struct LogViewerBuilder: Builder {
    public init() { }

    public func build(using dependencies: LogViewerDependencies) -> UIViewController {
        let logEntryDecryptor = dependencies.decryptionKey.map(LogEntryDecryptor.init)
        let repository = LogEntriesRepository(logs: dependencies.logs, logEntryDecryptor: logEntryDecryptor)
        let viewController = LogsViewerViewController(repository: repository)

        return viewController
    }
}
