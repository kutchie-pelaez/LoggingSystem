import Core
import Darwin
import Logging
import SignpostLogger

struct StdoutLogHandler: LogHandler {
    private let label: String
    private let loggerType: LoggerType

    private let dateFormatter = LogDateFormatter()

    init(label: String, loggerType: LoggerType) {
        self.label = label
        self.loggerType = loggerType
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

    private func signpostIndicator(for signpostMessage: SignpostMessage) -> String {
        switch signpostMessage {
        case .begin: return "🚩"
        case .end: return "🏁"
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

    private func write(entry: StdoutLogEntry) {
        var output = entry.description
        output.makeContiguousUTF8()
        output.utf8.withContiguousStorageIfAvailable { utf8Bytes in
            flockfile(stdout)
            defer { funlockfile(stdout) }
            _ = fwrite(utf8Bytes.baseAddress!, 1, utf8Bytes.count, stdout)
            _ = fflush(stdout)
        }
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
        let entryMessage: String
        var metadata = self.metadata.appending(metadata)

        switch loggerType {
        case .regular:
            entryMessage = [
                dateFormatter.currentTimestamp(),
                label.surroundedBy("[", "]"),
                hint(file: file, function: function, line: line),
                "-",
                indicator(for: level),
                message.description
            ].unwrapped().joined(separator: " ")

        case .signpost:
            guard let signpostMessage = SignpostMessage(rawValue: message.description) else {
                assertionFailure()
                return
            }

            let signpostSplits = label.split(separator: "::")
            let group = signpostSplits[safe: 1]
            let label = signpostSplits[safe: 2]

            guard let group, let label else {
                assertionFailure()
                return
            }

            entryMessage = [
                signpostIndicator(for: signpostMessage),
                dateFormatter.currentTimestamp(),
                label.surroundedBy("[", "]"),
                hint(file: file, function: function, line: line),
                signpostIndicator(for: signpostMessage)
            ].joined(separator: " ")
            metadata["signpostGroup"] = "\(group)"
        }

        let logEntry = StdoutLogEntry(message: entryMessage, metadata: metadata)
        write(entry: logEntry)
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
