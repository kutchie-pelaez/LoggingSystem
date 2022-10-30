import Foundation
import Logging

public struct SignpostLogger {
    private let logger: Logger

    public init(label: String, group: SignpostGroup) {
        let label = ["signpost", group.rawValue, label].joined(separator: "::")
        var logger = Logger(label: label)
        logger[metadataKey: "signpostID"] = "\(UUID().uuidString)"
        self.logger = logger
    }

    public func begin(file: String = #fileID, function: String = #function, line: UInt = #line) {
        log(.begin, file: file, function: function, line: line)
    }

    public func end(file: String = #fileID, function: String = #function, line: UInt = #line) {
        log(.end, file: file, function: function, line: line)
    }

    private func log(_ message: SignpostMessage, file: String, function: String, line: UInt) {
        let message = Logger.Message(stringLiteral: message.rawValue)
        logger.log(level: .info, message, file: file, function: function, line: line)
    }
}
