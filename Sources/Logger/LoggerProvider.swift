import Foundation

public protocol LoggerProvider {
    var logsURL: URL { get }
}

extension LoggerProvider {
    public var logsURL: URL {
        FileManager.default
            .documents
            .appendingPathComponent("logs")
    }
}
