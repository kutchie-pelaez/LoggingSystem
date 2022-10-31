import Core
import Foundation
import LogEntryEncryption
import Logging
import SignpostLogger
import Version

enum LogEntryType: String, Comparable, CustomStringConvertible {
    case log
    case signpost

    // MARK: Comparable

    static func < (lhs: LogEntryType, rhs: LogEntryType) -> Bool {
        switch (lhs, rhs) {
        case (.log, .signpost): return false
        case (.signpost, .log): return true
        case (.log, .log): return false
        case (.signpost, .signpost): return false
        }
    }

    // MARK: CustomStringConvertible

    var description: String {
        rawValue.capitalized
    }
}

enum LogEntry {
    struct Log {
        let message: String
        let metadata: Logger.Metadata?
        let level: Logger.Level
        let date: Date
        let file: String
        let function: String
        let label: String
        let line: Int
        let sessionNumber: Int
        let source: String
        let version: Version
    }

    struct Signpost {
        let message: SignpostMessage
        let id: String
        let group: String
        let date: Date
        let file: String
        let function: String
        let label: String
        let line: Int
        let sessionNumber: Int
        let source: String
        let version: Version
    }

    case log(Log)
    case signpost(Signpost)

    var entryType: LogEntryType {
        switch self {
        case .log: return .log
        case .signpost: return .signpost
        }
    }

    var level: Logger.Level {
        switch self {
        case .log(let log): return log.level
        case .signpost: return .info
        }
    }

    var date: Date {
        switch self {
        case .log(let log): return log.date
        case .signpost(let signpost): return signpost.date
        }
    }

    var label: String {
        switch self {
        case .log(let log): return log.label
        case .signpost(let signpost): return signpost.label
        }
    }

    var source: String {
        switch self {
        case .log(let log): return log.source
        case .signpost(let signpost): return signpost.source
        }
    }

    var function: String {
        switch self {
        case .log(let log): return log.function
        case .signpost(let signpost): return signpost.function
        }
    }

    var file: String {
        switch self {
        case .log(let log): return log.file
        case .signpost(let signpost): return signpost.file
        }
    }

    var line: Int {
        switch self {
        case .log(let log): return log.line
        case .signpost(let signpost): return signpost.line
        }
    }

    var version: Version {
        switch self {
        case .log(let log): return log.version
        case .signpost(let signpost): return signpost.version
        }
    }

    var sessionNumber: Int {
        switch self {
        case .log(let log): return log.sessionNumber
        case .signpost(let signpost): return signpost.sessionNumber
        }
    }
}

struct LogsQuery {
    let input: String?
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

final class LogEntriesRepository: LogsViewerItemsProviderDataSource {
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss.SSSZ"

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
                entries = entries.filter { entry in
                    switch entry {
                    case .log(let log):
                        return levels.contains(log.level)

                    case .signpost:
                        return levels.contains(.info)
                    }
                }
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
            if let input = query.input {
                entries = entriesFilteredByInput(entries: entries, input: input)
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

    private func entriesFilteredByInput(entries: [LogEntry], input: String) -> [LogEntry] {
        entries.filter { entry in
            let functionCondition = entry.function.contains(input)
            let fileCondition = entry.file.contains(input)

            let messageCondition: Bool
            switch entry {
            case .log(let log):
                messageCondition = log.message.contains(input)

            case .signpost(let signpost):
                messageCondition = signpost.message.rawValue.contains(input)
            }

            let signpostIDCondition: Bool
            switch entry {
            case .log:
                signpostIDCondition = false

            case .signpost(let signpost):
                signpostIDCondition = signpost.id.contains(input)
            }

            let signpostGroupCondition: Bool
            switch entry {
            case .log:
                signpostGroupCondition = false

            case .signpost(let signpost):
                signpostGroupCondition = signpost.group.contains(input)
            }

            let metadataCondition: Bool
            switch entry {
            case .log(let log):
                ifClause:
                if let metatadaValues = log.metadata.map(Logger.MetadataValue.dictionary).map(metatadaStringValues) {
                    for metatadaValue in metatadaValues {
                        if metatadaValue.contains(input) {
                            metadataCondition = true
                            break ifClause
                        }
                    }
                    metadataCondition = false
                } else {
                    metadataCondition = false
                }

            case .signpost:
                metadataCondition = false
            }

            return  functionCondition ||
                fileCondition ||
                messageCondition ||
                signpostIDCondition ||
                signpostGroupCondition ||
                metadataCondition
        }
    }

    private func metatadaStringValues(form metadataValue: Logger.MetadataValue) -> [String] {
        switch metadataValue {
        case .dictionary(let dictionary):
            return dictionary
                .map { metatadaStringValues(form: $1) }
                .flatten()

        case .array(let array):
            return array
                .map(metatadaStringValues)
                .flatten()

        case .string(let string):
            return [string]

        case .stringConvertible(let stringConvertible):
            return [stringConvertible.description]
        }
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

            let messageAndMetadata = rawEntry
                .split(maxSplits: 2) { $0.isWhitespace && $1 == "{" }
                .map(String.init)
            let message = messageAndMetadata[safe: 0]?.trimmingCharacters(in: .whitespaces)
            let rawMetadata = messageAndMetadata[safe: 1]

            guard let message else {
                return .failure(.invalidEntry(rawEntry: rawEntry))
            }

            guard let rawMetadata, var metadata = try? metadataDecoder.decode(rawMetadata) else {
                return .failure(.invalidMetadata(description: rawEntry))
            }

            switch message {
            case "SESSION_HEADER":
                headerMetadata = metadata
                continue

            default:
                guard var headerMetadata else {
                    return .failure(.noHeaderForEntry(rawEntry: rawEntry))
                }

                do {
                    let date = try extraxtDate(from: &metadata, key: "timestamp")
                    let file = try extraxtString(from: &metadata, key: "file")
                    let function = try extraxtString(from: &metadata, key: "function")
                    let label = try extraxtString(from: &metadata, key: "label")
                    let line = try extraxtInt(from: &metadata, key: "line")
                    let sessionNumber = try extraxtInt(from: &headerMetadata, key: "sessionNumber")
                    let source = try extraxtString(from: &metadata, key: "source")
                    let version = try extraxtVersion(from: &headerMetadata, key: "version")

                    let logEntry: LogEntry
                    if let signpostMessage = SignpostMessage(rawValue: message) {
                        let id = try extraxtString(from: &metadata, key: "signpostID")
                        let group = try extraxtString(from: &metadata, key: "signpostGroup")

                        logEntry = .signpost(LogEntry.Signpost(
                            message: signpostMessage, id: id, group: group,
                            date: date, file: file, function: function, label: label, line: line,
                            sessionNumber: sessionNumber, source: source, version: version
                        ))
                    } else {
                        let level = try extraxtLevel(from: &metadata, key: "level")

                        logEntry = .log(LogEntry.Log(
                            message: message, metadata: metadata, level: level,
                            date: date, file: file, function: function, label: label, line: line,
                            sessionNumber: sessionNumber, source: source, version: version
                        ))
                    }

                    logEntries.append(logEntry)
                } catch let error as LogEntriesRepositoryError {
                    return .failure(error)
                } catch {
                    assertionFailure()
                }
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
            if fileManager.directoryExists(at: logFilesURLProvider.logsDirectoryURL) {
                try fileManager.removeItem(at: logFilesURLProvider.logsDirectoryURL)
            }

            try fileManager.createDirectory(at: logFilesURLProvider.decryptedDirectoryURL)
            try fileManager.createFile(
                at: logFilesURLProvider.decryptedFileURL,
                contents: decryptedLogs, overwrite: true
            )

            if let encryptedLogs {
                try fileManager.createDirectory(at: logFilesURLProvider.encryptedDirectoryURL)
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

    private func requestLogEntriesGroups<T: Hashable & Comparable>(
        _ keyPath: KeyPath<LogEntry, T>
    ) -> [LogEntriesGroup<T>] {
        guard let entries = entriesResult.success else { return [] }

        var exntryValueToCount = [T: Int]()

        for entry in entries {
            let value = entry[keyPath: keyPath]
            exntryValueToCount[value] = (exntryValueToCount[value] ?? 0) + 1
        }

        return exntryValueToCount
            .map(LogEntriesGroup.init)
            .sorted { $0.entriesCount > $1.entriesCount }
    }

    // MARK: LogsViewerItemsProviderDataSource

    func avalilableEntryTypesDidReqest() -> [LogEntriesGroup<LogEntryType>] {
        requestLogEntriesGroups(\.entryType)
    }

    func avalilableLevelsDidReqest() -> [LogEntriesGroup<Logger.Level>] {
        requestLogEntriesGroups(\.level)
    }

    func avalilableLabelsDidReqest() -> [LogEntriesGroup<String>] {
        requestLogEntriesGroups(\.label)
    }

    func avalilableSourcesDidReqest() -> [LogEntriesGroup<String>] {
        requestLogEntriesGroups(\.source)
    }
}
