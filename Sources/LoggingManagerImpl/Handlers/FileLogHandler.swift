import Core
import CoreUtils
import Foundation
import LogEntryEncryption
import Logging
import SignpostLogger
import Version

private let loggingQueue = DispatchQueue(label: "com.kutchie-pelaez.Logging")
private let dateFormatter = LogDateFormatter()
private let logEntryMetadataEncoder = LogEntryMetadataEncoder()

protocol FileLogHandlerDelegate: AnyObject {
    func fileLogHandlerDidWriteHeader()
}

struct FileLogHandler: LogHandler {
    weak var delegate: FileLogHandlerDelegate?

    private let label: String
    private let loggerType: LoggerType
    private let fileHandle: FileHandle
    private let logEntryEncryptor: LogEntryEncryptor?
    private let sessionNumber: Int
    private let shouldWriteHeader: Resolver<Bool>

    init(
        label: String,
        loggerType: LoggerType,
        fileHandle: FileHandle,
        logEntryEncryptor: LogEntryEncryptor?,
        sessionNumber: Int,
        shouldWriteHeader: @escaping Resolver<Bool>
    ) {
        self.label = label
        self.loggerType = loggerType
        self.fileHandle = fileHandle
        self.logEntryEncryptor = logEntryEncryptor
        self.sessionNumber = sessionNumber
        self.shouldWriteHeader = shouldWriteHeader
    }

    private func writeHeaderIfNeeded() {
        guard shouldWriteHeader() else { return }

        delegate?.fileLogHandlerDidWriteHeader()
        let headerMetadata = makeHeaderMetadata()
        write(message: nil, with: headerMetadata)
    }

    private func makeHeaderMetadata() -> Logger.Metadata {
        let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let version = safeUndefinedIfNil(versionString.flatMap { try? Version($0) }?.description, "n/a")

        return [
            "sessionNumber": "\(sessionNumber)",
            "version": "\(version)"
        ]
    }

    private func makeMergedMetadata(
        message: Logger.Message, logMetadata: Logger.Metadata?, level: Logger.Level,
        source: String, file: String, function: String, line: UInt
    ) -> Logger.Metadata {
        let timestamp = dateFormatter.currentTimestamp()
        let fileLastComponent = safeUndefinedIfNil(file.split(separator: "/").last, "n/a")

        var coreMetadata: Logger.Metadata = [
            "file": "\(fileLastComponent)",
            "function": "\(function)",
            "line": "\(line)",
            "source": "\(source)",
            "timestamp": "\(timestamp)"
        ]

        switch loggerType {
        case .regular:
            coreMetadata["label"] = "\(label)"
            coreMetadata["level"] = "\(level)"

        case .signpost:
            let signpostSplits = label.split(separator: "::")
            let group = signpostSplits[safe: 1]
            let label = signpostSplits[safe: 2]

            guard let group, let label, SignpostMessage(rawValue: message.description) != nil else {
                assertionFailure()
                break
            }

            coreMetadata["label"] = "\(label)"
            coreMetadata["signpostGroup"] = "\(group)"
        }

        return coreMetadata.appending(metadata).appending(logMetadata)
    }

    private func write(message: Logger.Message?, with metadata: Logger.Metadata) {
        do {
            let encodedMetadata = try logEntryMetadataEncoder.encode(metadata)
            var logEntry = [message?.description, encodedMetadata]
                .unwrapped()
                .joined(separator: " ")

            if let logEntryEncryptor {
                do {
                    logEntry = try logEntryEncryptor.encrypt(logEntry)
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
            logEntry.append("\n")

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
            writeHeaderIfNeeded()
            let metadata = makeMergedMetadata(
                message: message, logMetadata: metadata, level: level,
                source: source, file: file, function: function, line: line
            )
            write(message: message, with: metadata)
        }
    }
}
