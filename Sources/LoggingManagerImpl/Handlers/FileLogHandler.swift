import Core
import CoreUtils
import Foundation
import LogEntryEncryption
import Logging

struct FileLogHandler: LogHandler {
    private let label: String
    private let logsFileURL: URL
    private let fileHandle: FileHandle
    private let logEntryEncryptor: LogEntryEncryptor
    private let sessionNumberResolver: Resolver<Int?>

    private let dateFormatter = LogDateFormatter()

    init(
        label: String,
        logsFileURL: URL,
        fileHandle: FileHandle,
        logEntryEncryptor: LogEntryEncryptor,
        sessionNumberResolver: @escaping Resolver<Int?>
    ) {
        self.label = label
        self.logsFileURL = logsFileURL
        self.fileHandle = fileHandle
        self.logEntryEncryptor = logEntryEncryptor
        self.sessionNumberResolver = sessionNumberResolver
    }

    private func fullMetadata(
        merging metadataToMerge: Logger.Metadata?,
        level: Logger.Level,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) -> Logger.Metadata {
        var additionalMetadata: Logger.Metadata = [
            "label": "\(label)",
            "level": "\(level)",
            "module": "\(source)",
            "function": "\(function)",
            "line": "\(line)"
        ]
        if let fileLastComponent = file.split(separator: "/").last {
            additionalMetadata["file"] = "\(fileLastComponent)"
        }
        if let sessionNumber = sessionNumberResolver() {
            additionalMetadata["sessionNumber"] = "\(sessionNumber)"
        }

        return additionalMetadata
            .appending(self.metadata)
            .appending(metadataToMerge)
    }

    private func writeEntry(_ logEntry: FileLogEntry) throws {
        let encryptedLogEnrty = logEntryEncryptor.encrypt(logEntry.description)

        guard let data = encryptedLogEnrty.description.data(using: .utf8) else {
            throw ContextError(
                message: "Failed to get utf8 data from encrypted log enrty",
                context: encryptedLogEnrty
            )
        }

        try fileHandle.write(contentsOf: data)
    }

    // MARK: LogHandler

    var metadata: Logger.Metadata = [:]

    var logLevel: Logger.Level = .trace

    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
        let message = [
            dateFormatter.currentTimestamp().surroundedBy("[", "]"),
            message.description
        ].unwrapped().joined(separator: " ")
        let metadata = fullMetadata(merging: metadata, level: level, source: source, file: file, function: function, line: line)
        let logEntry = FileLogEntry(message: message, metadata: metadata)

        do {
            try writeEntry(logEntry)
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
}

private struct FileLogEntry: CustomStringConvertible {
    private let message: String
    private let metadata: Logger.Metadata

    private let logEntryMetadataEncoder = LogEntryMetadataEncoder()

    init(message: String, metadata: Logger.Metadata) {
        self.message = message
        self.metadata = metadata
    }

    // MARK: CustomStringConvertible

    var description: String {
        let encodedMetadata = logEntryMetadataEncoder.encode(metadata)

        return [message, encodedMetadata]
            .unwrapped()
            .joined(separator: " ")
            .appending("\n")
    }
}
