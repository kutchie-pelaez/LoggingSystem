import Core
import Foundation
import LogEntryEncryption
import Logging

struct LogEntry {
    let message: String
    let metadata: Logger.Message?
    let date: Date
    let level: Logger.Level
    let label: String
    let source: String
    let function: String
    let file: String
    let line: Int
    let sessionNumber: Int
}

struct LogsQuery {
    let levels: Set<Logger.Level>?
    let datesRange: ClosedRange<Date>?
}

enum LogEntriesRepositoryError: Error {
    case noEntries
    case invalidDecryptionKey
    case missingMetadata(rawEntry: String)
}

final class LogEntriesRepository {
    private let logs: Data
    private let logEntryDecryptor: LogEntryDecryptor?

    private lazy var entriesResult: Result<[LogEntry], Error> = {
        do {
            let entries = try parseLogs()

            return .success(entries)
        } catch {
            return .failure(error)
        }
    }()

    init(logs: Data, logEntryDecryptor: LogEntryDecryptor?) {
        self.logs = logs
        self.logEntryDecryptor = logEntryDecryptor
    }

    func entries(for query: LogsQuery?) throws -> [LogEntry] {
        switch entriesResult {
        case .success(var entries):
            guard let query else {
                return entries
            }

            if let levels = query.levels {
                entries = entries.filter { levels.contains($0.level) }
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
        []
    }
}
