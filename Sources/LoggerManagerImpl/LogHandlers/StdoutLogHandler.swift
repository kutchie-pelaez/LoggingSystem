import Core
import Foundation
import Logging
import Tagging

struct StdoutLogHandler: LogHandler {
    private let type: LoggerType

    init(type: LoggerType) {
        self.type = type
    }

    private func write(entry: StdoutLogEntry) {
        var rawEntry = entry.description
        rawEntry.makeContiguousUTF8()
        rawEntry.utf8.withContiguousStorageIfAvailable { utf8Bytes in
            flockfile(stdout)
            defer { funlockfile(stdout) }
            fwrite(utf8Bytes.baseAddress!, 1, utf8Bytes.count, stdout)
            fflush(stdout)
        }
    }

    private func indicator(for level: Logger.Level) -> String? {
        switch level {
        case .notice: return "👀"
        case .warning: return "⚠️"
        case .error: return "⛔️"
        case .critical: return "📛"
        default: return nil
        }
    }

    private func indicator(for tag: LogEntryTag?) -> String? {
        switch tag {
        case .signpostBegin: return "🚩"
        case .signpostEnd: return "🏁"
        default: return nil
        }
    }

    private func hint(file: String, function: String, line: UInt) -> String {
        let fileStem = file
            .split(separator: "/")
            .last?
            .split(separator: ".")
            .first
            .map(String.init)

        return [fileStem, function, line.description]
            .unwrapped()
            .joined(separator: "::")
    }

    // MARK: LogHandler

    var metadata: Logger.Metadata = [:]

    var logLevel: Logger.Level = .trace

    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    func log(
        level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?,
        source _: String, file: String, function: String, line: UInt
    ) {
        let entryTag = RawLogEntry(message.description).tag
        let entryMessage: String
        let entryMetadata = self.metadata.appending(metadata)

        let timestampPart = LogDateFormatter.currentTimestamp()
        let labelPart = type.label.surroundedBy("[", "]")
        let hintPart = hint(file: file, function: function, line: line)
        let threadPart: String? = {
            guard !Thread.isMainThread else { return nil }
            let threadName = Thread.current.name ?? "\(Thread.current)"
            return ("🧵" + threadName).surroundedBy("[", "]")
        }()

        switch type {
        case .default:
            entryMessage = [
                timestampPart, labelPart, threadPart, hintPart,
                "-", indicator(for: level), message.description
            ].unwrapped().joined(separator: " ")

        case .signpost:
            entryMessage = [
                indicator(for: entryTag),
                timestampPart, labelPart, threadPart, threadPart, hintPart,
                indicator(for: entryTag)
            ].unwrapped().joined(separator: " ")
        }

        write(entry: StdoutLogEntry(
            message: entryMessage,
            metadata: entryMetadata
        ))
    }
}

private struct StdoutLogEntry: CustomStringConvertible {
    private let message: String
    private let metadata: Logger.Metadata?

    init(message: String, metadata: Logger.Metadata?) {
        self.message = message
        if let metadata = metadata, metadata.isNotEmpty {
            self.metadata = metadata
        } else {
            self.metadata = nil
        }
    }

    private func metadataValueDescription(
        isRoot: Bool = false,
        key: String? = nil,
        metadataValue: Logger.MetadataValue,
        indentation: Int = 0
    ) -> String {
        func stringConvertibleDescription(for stringConvertible: some CustomStringConvertible) -> String {
            ["-", key.map { $0 + ":" }, stringConvertible.description]
                .unwrapped()
                .joined(separator: " ")
                .indented(indentation)
        }

        func parentDescription(count: Int, term: String) -> String? {
            guard !isRoot else { return nil }

            return ["▿", key.map { $0 + ":" }, "(\(count) \(term)\(count > 1 ? "s" : ""))"]
                .unwrapped()
                .joined(separator: " ")
                .indented(indentation)
        }

        let dictionaryMapping = { metadataValueDescription(key: $0, metadataValue: $1, indentation: indentation + 2) }
        let arrayMapping = { dictionaryMapping(nil, $0) }

        switch metadataValue {
        case .string(let string):
            return stringConvertibleDescription(for: string)

        case .stringConvertible(let stringConvertible):
            return stringConvertibleDescription(for: stringConvertible)

        case .dictionary(let dictionary):
            return dictionary
                .sorted { $0.key < $1.key }
                .map(dictionaryMapping)
                .prepending(parentDescription(count: dictionary.count, term: "pair"))
                .unwrapped()
                .joined(separator: "\n")

        case .array(let array):
            return array
                .map(arrayMapping)
                .prepending(parentDescription(count: array.count, term: "element"))
                .unwrapped()
                .joined(separator: "\n")
        }
    }

    // MARK: CustomStringConvertible

    var description: String {
        let metadataDescription = metadata
            .map(Logger.MetadataValue.dictionary)
            .map { metadataValueDescription(isRoot: true, metadataValue: $0) }

        return [message, metadataDescription, ""]
            .unwrapped()
            .joined(separator: "\n")
    }
}
