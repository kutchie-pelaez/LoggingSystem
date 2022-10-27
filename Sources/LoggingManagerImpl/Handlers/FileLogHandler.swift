import Core
import CoreUtils
import Foundation
import LogEntryEncryption
import Logging

struct FileLogHandler: LogHandler {
    private static let writingQueue = DispatchQueue(label: "com.kutchie-pelaez.Logging")

    private let label: String
    private let logsFileURL: URL
    private let fileHandle: FileHandle
    private let logEntryEncryptor: LogEntryEncryptor
    private let sessionNumberResolver: Resolver<Int?>

    private let dateFormatter = LogDateFormatter()
    private let logEntryMetadataEncoder = LogEntryMetadataEncoder()

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

    private func write(message: String, with metadata: Logger.Metadata) {
        do {
            let encodedMetadata = logEntryMetadataEncoder.encode(metadata)
            let rawLogEntry = [message, encodedMetadata]
                .joined(separator: " ")
            let encryptedLogEnrty = logEntryEncryptor.encrypt(rawLogEntry)
                .appending("\n")

            guard let logEnrtyData = encryptedLogEnrty.data(using: .utf8) else {
                throw ContextError(
                    message: "Failed to get utf8 data from encrypted log enrty",
                    context: encryptedLogEnrty
                )
            }

            try fileHandle.seekToEnd()
            try fileHandle.write(contentsOf: logEnrtyData)
            try fileHandle.synchronize()
        } catch {
            assertionFailure(error.localizedDescription)
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
        source: String, file: String, function: String, line: UInt
    ) {
        Self.writingQueue.async {
            let message = [
                dateFormatter.currentTimestamp().surroundedBy("[", "]"),
                message.description
            ].unwrapped().joined(separator: " ")
            let metadata = fullMetadata(
                merging: metadata, level: level,
                source: source, file: file, function: function, line: line
            )

            write(message: message, with: metadata)
        }
    }
}
