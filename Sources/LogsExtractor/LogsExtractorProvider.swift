import Core
import DeviceKit
import Foundation

public protocol LogsExtractorProvider {
    var logsURL: URL { get }
}

extension LogsExtractorProvider {
    public var logsURL: URL {
        FileManager.default
            .documents
            .appendingPathComponent("logs")
    }
}
