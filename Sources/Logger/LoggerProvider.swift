import Foundation

public protocol LoggerProvider {
    var logsURL: URL { get }
    var sessionAdditionalParams: [String] { get }
}

extension LoggerProvider {
    public var logsURL: URL {
        FileManager.default
            .documents
            .appendingPathComponent("logs")
    }

    public var sessionAdditionalParams: [String] {
        []
    }
}
