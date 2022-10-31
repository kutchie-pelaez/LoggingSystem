import Foundation
import Logging
import Tagging

public struct SignpostLogger {
    @usableFromInline
    let logger: Logger

    public init(label: String, group: String) {
        let label = LoggerType.signpost(label: label, group: group).description
        let id = UUID().uuidString

        var logger = Logger(label: label)
        logger[metadataKey: MetadataKeys.signpostID.rawValue] = "\(id)"
        logger[metadataKey: MetadataKeys.signpostGroup.rawValue] = "\(group)"

        self.logger = logger
    }

    @inlinable
    public func begin(file: String = #fileID, function: String = #function, line: UInt = #line) {
        log(.signpostBegin, file: file, function: function, line: line)
    }

    @inlinable
    public func end(file: String = #fileID, function: String = #function, line: UInt = #line) {
        log(.signpostEnd, file: file, function: function, line: line)
    }

    @usableFromInline
    func log(_ tag: LogEntryTag, file: String = #fileID, function: String = #function, line: UInt = #line) {
        logger.info(Logger.Message(stringLiteral: tag.rawValue), file: file, function: function, line: line)
    }
}
