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
    case invalidDecryptionKey
    case noHeaderForEntry(rawEntry: String)
    case invalidHeader(rawHeader: String)
    case invalidEntry(rawEntry: String)
    case invalidMetadata(description: String)
}

final class LogEntriesRepository {
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = ""

        return dateFormatter
    }()

    private let logs: Data
    private let logEntryDecryptor: LogEntryDecryptor?

    private lazy var entriesResult: Result<[LogEntry], LogEntriesRepositoryError> = {
        do {
            let entries = try parseLogs()

            return .success(entries)
        } catch let error as LogEntriesRepositoryError {
            return .failure(error)
        } catch {
            assertionFailure()
            return .failure(.noEntries)
        }
    }()

    init(logs: Data, logEntryDecryptor: LogEntryDecryptor?) {
        self.logs = logs
        self.logEntryDecryptor = logEntryDecryptor
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

    private func parseLogs() throws -> [LogEntry] {
        guard let rawLogs = String(data: logs, encoding: .utf8), rawLogs.isNotEmpty else {
            throw LogEntriesRepositoryError.noEntries
        }

        let metadataDecoder = LogEntryMetadataDecoder()
        var rawLogEntries = rawLogs.split(separator: "\n")
        var headerMetadata: Logger.Metadata?
        var logEntries = [LogEntry]()
        logEntries.reserveCapacity(rawLogEntries.count)

        while rawLogEntries.isNotEmpty {
            let rawEntry = String(rawLogEntries.removeFirst())

            guard !rawEntry.starts(with: "{") else {
                if let metadata = try? metadataDecoder.decode(rawEntry) {
                    headerMetadata = metadata
                } else {
                    throw LogEntriesRepositoryError.invalidHeader(rawHeader: rawEntry)
                }

                continue
            }

            let messageAndMetadata = rawEntry
                .split(separator: " ", maxSplits: 2)
                .map(String.init)
            let message = messageAndMetadata[safe: 0]
            let rawMetadata = messageAndMetadata[safe: 1]

            guard let message, let rawMetadata, var metadata = try? metadataDecoder.decode(rawMetadata) else {
                throw LogEntriesRepositoryError.invalidEntry(rawEntry: rawEntry)
            }

            guard var headerMetadata else {
                throw LogEntriesRepositoryError.noHeaderForEntry(rawEntry: rawEntry)
            }

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
        }

        return logEntries
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
