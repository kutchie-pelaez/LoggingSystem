import Foundation

public protocol LoggingManagerProvider {
    var encryptionKey: String? { get }
    func logsFileURL(for logsFileName: String) -> URL
}

extension LoggingManagerProvider {
    public var encryptionKey: String? { nil }

    public func logsFileURL(for logsFileName: String) -> URL {
        FileManager.default
            .documents
            .appending(path: "logs")
            .appending(path: logsFileName)
    }
}

struct DefaultLoggingManagerProvider: LoggingManagerProvider { }
