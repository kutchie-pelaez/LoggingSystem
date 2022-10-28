import Core
import CoreUtils
import Foundation
import LogEntryEncryption
import Logging

struct FileLogHandler: LogHandler {
    private static let queue = DispatchQueue(label: "com.kutchie-pelaez.Logging")

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

    private func mergedMetadata(
        logMetadata: Logger.Metadata?, level: Logger.Level,
        source: String, file: String, function: String, line: UInt
    ) -> Logger.Metadata {
        let timestamp = dateFormatter.currentTimestamp()
        var coreMetadata: Logger.Metadata = [
            "timestamp": "\(timestamp)",
            "label": "\(label)",
            "level": "\(level)",
            "source": "\(source)",
            "function": "\(function)",
            "line": "\(line)"
        ]
        if let fileLastComponent = file.split(separator: "/").last {
            coreMetadata["file"] = "\(fileLastComponent)"
        }
        if let sessionNumber = sessionNumberResolver() {
            coreMetadata["sessionNumber"] = "\(sessionNumber)"
        }

        return coreMetadata
            .appending(metadata)
            .appending(logMetadata)
    }

    private func write(message: Logger.Message, with metadata: Logger.Metadata) {
        do {
            let encodedMetadata = try logEntryMetadataEncoder.encode(metadata)
            let rawLogEntry = [message.description, encodedMetadata]
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
        Self.queue.async {
            let metadata = mergedMetadata(
                logMetadata: metadata, level: level,
                source: source, file: file, function: function, line: line
            )
            write(message: message, with: metadata)
        }
    }
}
