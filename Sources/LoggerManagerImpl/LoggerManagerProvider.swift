import Foundation

public protocol LoggerManagerProvider {
    var encryptionKey: String? { get }
    func logsFileURL(for logsFileName: String) -> URL
}

extension LoggerManagerProvider {
    public var encryptionKey: String? { nil }

    public func logsFileURL(for logsFileName: String) -> URL {
        FileManager.default
            .documents
            .appending(path: "logs")
            .appending(path: logsFileName)
    }
}

struct DefaultLoggerManagerProvider: LoggerManagerProvider { }
