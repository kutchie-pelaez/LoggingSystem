import Core
import CoreUtils
import Foundation
import LogEntryEncryption
import Logging

private let loggingQueue = DispatchQueue(label: "com.kutchie-pelaez.Logging")

struct FileLogHandler: LogHandler {
    private let label: String
    private let fileHandle: FileHandle
    private let logEntryEncryptor: LogEntryEncryptor?
    private let sessionNumberResolver: Resolver<Int?>

    private let dateFormatter = LogDateFormatter()
    private let logEntryMetadataEncoder = LogEntryMetadataEncoder()

    init(
        label: String,
        fileHandle: FileHandle,
        logEntryEncryptor: LogEntryEncryptor?,
        sessionNumberResolver: @escaping Resolver<Int?>
    ) {
        self.label = label
        self.fileHandle = fileHandle
        self.logEntryEncryptor = logEntryEncryptor
        self.sessionNumberResolver = sessionNumberResolver
    }

    private func mergedMetadata(
        logMetadata: Logger.Metadata?, level: Logger.Level,
        source: String, file: String, function: String, line: UInt
    ) -> Logger.Metadata {
        let timestamp = dateFormatter.currentTimestamp()
        let fileLastComponent = safeUndefinedIfNil(file.split(separator: "/").last, "n/a")
        let sessionNumber = safeUndefinedIfNil(sessionNumberResolver().map(String.init), "n/a")

        let coreMetadata: Logger.Metadata = [
            "timestamp": "\(timestamp)",
            "level": "\(level)",
            "label": "\(label)",
            "source": "\(source)",
            "function": "\(function)",
            "file": "\(fileLastComponent)",
            "line": "\(line)",
            "sessionNumber": "\(sessionNumber)"
        ]

        return coreMetadata
            .appending(metadata)
            .appending(logMetadata)
    }

    private func write(message: Logger.Message, with metadata: Logger.Metadata) {
        do {
            let encodedMetadata = try logEntryMetadataEncoder.encode(metadata)
            var logEntry = [message.description, encodedMetadata]
                .joined(separator: " ")
            if let logEntryEncryptor {
                logEntry = logEntryEncryptor.encrypt(logEntry)
                    .appending("\n")
            } else {
                logEntry.append("\n")
            }

            guard let logEnrtyData = logEntry.data(using: .utf8) else {
                throw ContextError(
                    message: "Failed to get utf8 data from encrypted log enrty",
                    context: logEntry
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
        loggingQueue.async {
            let metadata = mergedMetadata(
                logMetadata: metadata, level: level,
                source: source, file: file, function: function, line: line
            )
            write(message: message, with: metadata)
        }
    }
}
