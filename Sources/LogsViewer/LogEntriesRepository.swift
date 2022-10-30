import Core
import Foundation
import LogEntryEncryption
import Logging
import Version

struct LogEntry {
    let message: String
    let metadata: Logger.Metadata?
    let date: Date
    let level: Logger.Level
    let label: String
    let source: String
    let function: String
    let file: String
    let line: Int
    let version: Version
    let sessionNumber: Int
}

struct LogsQuery {
    let levels: Set<Logger.Level>?
    let sessionNumbersRange: ClosedRange<Int>?
    let versionsRange: ClosedRange<Version>?
    let datesRange: ClosedRange<Date>?
}

enum LogEntriesRepositoryError: Error {
    case noEntries
    case invalidDecryptionKey(description: String)
    case noHeaderForEntry(rawEntry: String)
    case invalidHeader(rawHeader: String)
    case invalidEntry(rawEntry: String)
    case invalidMetadata(description: String)
}

final class LogEntriesRepository {
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ssZ"

        return dateFormatter
    }()

    private let logs: Data
    private let logFilesURLProvider: LogFilesURLProvider
    private var logEntryDecryptor: LogEntryDecryptor?

    private lazy var entriesResult = recreateEntries()
    private var decryptedLogs: Data?

    init(logs: Data, logFilesURLProvider: LogFilesURLProvider, decryptionKey: String?) {
        self.logs = logs
        self.logFilesURLProvider = logFilesURLProvider
        self.logEntryDecryptor = decryptionKey.map(LogEntryDecryptor.init)
    }

    func entries(for query: LogsQuery?) throws -> [LogEntry] {
        switch entriesResult {
        case .success(var entries):
            guard let query else { return entries }

            if let levels = query.levels {
                entries = entries.filter { levels.contains($0.level) }
            }
            if let sessionNumbersRange = query.sessionNumbersRange {
                entries = entries.filter { sessionNumbersRange ~= $0.sessionNumber }
            }
            if let versionsRange = query.versionsRange {
                entries = entries.filter { versionsRange ~= $0.version }
            }
            if let datesRange = query.datesRange {
                entries = entries.filter { datesRange ~= $0.date }
            }

            return entries

        case .failure(let error):
            throw error
        }
    }

    func setDecryptionKey(_ decryptionKey: String) {
        logEntryDecryptor = LogEntryDecryptor(decryptionKey: decryptionKey)
        entriesResult = recreateEntries()
    }

    private func recreateEntries() -> Result<[LogEntry], LogEntriesRepositoryError> {
        let entriesResult = parseLogs()
        if case .success = entriesResult {
            createTemporaryFiles()
        }

        return entriesResult
    }

    private func parseLogs() -> Result<[LogEntry], LogEntriesRepositoryError> {
        guard let rawLogs = String(data: logs, encoding: .utf8), rawLogs.isNotEmpty else {
            return .failure(.noEntries)
        }

        let metadataDecoder = LogEntryMetadataDecoder()
        var rawLogEntries = rawLogs.split(separator: "\n")
        var rawDecryptedEntries = logEntryDecryptor.map { _ in [String]() }
        var headerMetadata: Logger.Metadata?
        var logEntries = [LogEntry]()
        logEntries.reserveCapacity(rawLogEntries.count)

        while rawLogEntries.isNotEmpty {
            var rawEntry = String(rawLogEntries.removeFirst())

            if let logEntryDecryptor {
                do {
                    rawEntry = try logEntryDecryptor.decrypt(rawEntry)
                    rawDecryptedEntries?.append(rawEntry)
                } catch {
                    return .failure(.invalidDecryptionKey(description: error.localizedDescription))
                }
            }

            guard !rawEntry.starts(with: "{") else {
                if let metadata = try? metadataDecoder.decode(rawEntry) {
                    headerMetadata = metadata
                } else {
                    return .failure(.invalidHeader(rawHeader: rawEntry))
                }

                continue
            }

            let messageAndMetadata = rawEntry
                .split(maxSplits: 2) { $0.isWhitespace && $1 == "{" }
                .map(String.init)
            let message = messageAndMetadata[safe: 0]?
                .trimmingCharacters(in: .whitespaces)
            let rawMetadata = messageAndMetadata[safe: 1]

            guard let message, let rawMetadata, var metadata = try? metadataDecoder.decode(rawMetadata) else {
                return .failure(.invalidEntry(rawEntry: rawEntry))
            }

            guard var headerMetadata else {
                return .failure(.noHeaderForEntry(rawEntry: rawEntry))
            }

            do {
                let date = try extraxtDate(from: &metadata, key: "timestamp")
                let level = try extraxtLevel(from: &metadata, key: "level")
                let label = try extraxtString(from: &metadata, key: "label")
                let source = try extraxtString(from: &metadata, key: "source")
                let function = try extraxtString(from: &metadata, key: "function")
                let file = try extraxtString(from: &metadata, key: "file")
                let line = try extraxtInt(from: &metadata, key: "line")
                let version = try extraxtVersion(from: &headerMetadata, key: "version")
                let sessionNumber = try extraxtInt(from: &headerMetadata, key: "sessionNumber")

                logEntries.append(LogEntry(
                    message: message, metadata: metadata, date: date, level: level,
                    label: label, source: source, function: function, file: file, line: line,
                    version: version, sessionNumber: sessionNumber
                ))
            } catch let error as LogEntriesRepositoryError {
                return .failure(error)
            } catch {
                assertionFailure()
            }
        }

        if let rawDecryptedEntries {
            decryptedLogs = rawDecryptedEntries
                .joined(separator: "\n")
                .data(using: .utf8)
        }

        return .success(logEntries)
    }

    private func createTemporaryFiles() {
        let fileManager = FileManager.default
        let decryptedLogs = decryptedLogs ?? logs
        let encryptedLogs = logEntryDecryptor.map { _ in logs }

        do {
            try fileManager.createDirectory(at: logFilesURLProvider.decryptedFileURL.deletingLastPathComponent())
            try fileManager.createFile(
                at: logFilesURLProvider.decryptedFileURL,
                contents: decryptedLogs, overwrite: true
            )

            if let encryptedLogs {
                try fileManager.createDirectory(at: logFilesURLProvider.encryptedFileURL.deletingLastPathComponent())
                try fileManager.createFile(
                    at: logFilesURLProvider.encryptedFileURL,
                    contents: encryptedLogs, overwrite: true
                )
            }
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    private func extraxtString(from metadata: inout Logger.Metadata, key: String) throws -> String {
        guard case .string(let string) = metadata.removeValue(forKey: key) else {
            throw LogEntriesRepositoryError.invalidMetadata(
                description: "Expected \(key) value as string in \(metadata)"
            )
        }

        return string
    }

    private func extraxtDate(from metadata: inout Logger.Metadata, key: String) throws -> Date {
        let rawString = try extraxtString(from: &metadata, key: key)

        guard let date = Self.dateFormatter.date(from: rawString) else {
            throw LogEntriesRepositoryError.invalidMetadata(
                description: "Invalid date format for \(rawString) for key \(key) in \(metadata)"
            )
        }

        return date
    }

    private func extraxtLevel(from metadata: inout Logger.Metadata, key: String) throws -> Logger.Level {
        let rawString = try extraxtString(from: &metadata, key: key)

        guard let level = Logger.Level(rawValue: rawString) else {
            throw LogEntriesRepositoryError.invalidMetadata(
                description: "Invalid level format for \(rawString) for key \(key) in \(metadata)"
            )
        }

        return level
    }

    private func extraxtInt(from metadata: inout Logger.Metadata, key: String) throws -> Int {
        let rawString = try extraxtString(from: &metadata, key: key)

        guard let int = Int(rawString) else {
            throw LogEntriesRepositoryError.invalidMetadata(
                description: "Failed to convert \(rawString) to Int for key \(key) in \(metadata)"
            )
        }

        return int
    }

    private func extraxtVersion(from metadata: inout Logger.Metadata, key: String) throws -> Version {
        let rawString = try extraxtString(from: &metadata, key: key)

        guard let version = try? Version(rawString) else {
            throw LogEntriesRepositoryError.invalidMetadata(
                description: "Failed to convert \(rawString) to Version for key \(key) in \(metadata)"
            )
        }

        return version
    }
}
