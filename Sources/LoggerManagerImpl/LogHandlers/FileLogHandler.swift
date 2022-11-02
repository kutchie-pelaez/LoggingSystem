import Core
import CoreUtils
import Encryption
import Foundation
import Logging
import Tagging
import Version

protocol FileLogHandlerDelegate: AnyObject {
    func fileLogHandlerDidWriteHeader()
}

struct FileLogHandler: LogHandler {
    private static let queue = DispatchQueue(label: "com.kutchie-pelaez.LoggingSystem")

    weak var delegate: FileLogHandlerDelegate?

    private let type: LoggerType
    private let fileHandle: FileHandle
    private let logEntryEncryptor: LogEntryEncryptor?
    private let sessionNumber: Int
    private let shouldWriteHeader: Resolver<Bool>

    private let logEntryMetadataEncoder = LogEntryMetadataEncoder()

    init(
        type: LoggerType,
        fileHandle: FileHandle,
        logEntryEncryptor: LogEntryEncryptor?,
        sessionNumber: Int,
        shouldWriteHeader: @escaping Resolver<Bool>
    ) {
        self.type = type
        self.fileHandle = fileHandle
        self.logEntryEncryptor = logEntryEncryptor
        self.sessionNumber = sessionNumber
        self.shouldWriteHeader = shouldWriteHeader
    }

    private func writeHeaderIfNeeded() {
        guard shouldWriteHeader() else { return }

        delegate?.fileLogHandlerDidWriteHeader()
        let headerMetadata = makeHeaderMetadata()
        write(tag: .sessionHeader, message: nil, metadata: headerMetadata)
    }

    private func write(tag: LogEntryTag?, message: Logger.Message?, metadata: Logger.Metadata) {
        do {
            let encodedMetadata = try logEntryMetadataEncoder.encode(metadata)
            let rawEntry = RawLogEntry(tag: tag, message: message?.description, metadata: encodedMetadata)
            var entryString = rawEntry.description

            if let logEntryEncryptor {
                do { entryString = try logEntryEncryptor.encrypt(entryString) }
                catch { assertionFailure(error.localizedDescription) }
            }
            entryString.append("\n")

            guard let entryData = entryString.data(using: .utf8) else {
                throw ContextError(
                    message: "Failed to get utf8 data from encrypted log enrty",
                    context: entryString
                )
            }

            try fileHandle.seekToEnd()
            try fileHandle.write(contentsOf: entryData)
            try fileHandle.synchronize()
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    private func makeHeaderMetadata() -> Logger.Metadata {
        let versionDescription = {
            let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            let version = versionString.flatMap { try? Version($0) }

            if let version {
                return version.description
            } else {
                assertionFailure("Invalid version format")
                return "n/a"
            }
        }()

        return [
            MetadataKeys.sessionNumber.rawValue: "\(sessionNumber)",
            MetadataKeys.version.rawValue: "\(versionDescription)"
        ]
    }

    private func makeEntryMetadata(
        logMetadata: Logger.Metadata?,
        level: Logger.Level, source: String,
        file: String, function: String, line: UInt
    ) -> Logger.Metadata {
        let timestamp = LogDateFormatter.currentTimestamp()
        let fileLastComponent = {
            if let lastFileComponent = file.split(separator: "/").last {
                return lastFileComponent
            } else {
                assertionFailure("Ivalid file format")
                return "n/a"
            }
        }()

        var coreMetadata: Logger.Metadata = [
            MetadataKeys.file.rawValue: "\(fileLastComponent)",
            MetadataKeys.function.rawValue: "\(function)",
            MetadataKeys.label.rawValue: "\(type.label)",
            MetadataKeys.line.rawValue: "\(line)",
            MetadataKeys.source.rawValue: "\(source)",
            MetadataKeys.timestamp.rawValue: "\(timestamp)"
        ]

        if !Thread.isMainThread {
            let threadName = Thread.current.name ?? "\(Thread.current)"
            coreMetadata[MetadataKeys.thread.rawValue] = "\(threadName)"
        }

        switch type {
        case .default:
            coreMetadata[MetadataKeys.level.rawValue] = "\(level)"

        case .signpost:
            break
        }

        return coreMetadata
            .appending(metadata)
            .appending(logMetadata)
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
            let tag = RawLogEntry(message.description).tag
            let metadata = makeEntryMetadata(
                logMetadata: metadata,
                level: level, source: source,
                file: file, function: function, line: line
            )

            writeHeaderIfNeeded()
            write(tag: tag, message: message, metadata: metadata)
        }
    }
}
