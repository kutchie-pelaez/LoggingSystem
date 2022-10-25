import Foundation
import LogEntryEncryption
import LogsExtractor

final class LogsExtractorImpl: LogsExtractor {
    private let logEntryDecryptor: LogEntryDecryptor
    private let logEntryEncryptor: LogEntryEncryptor
    private let logsDirectoryURL: URL

    init(logEntryDecryptor: LogEntryDecryptor, logEntryEncryptor: LogEntryEncryptor, logsDirectoryURL: URL) {
        self.logEntryDecryptor = logEntryDecryptor
        self.logEntryEncryptor = logEntryEncryptor
        self.logsDirectoryURL = logsDirectoryURL
    }

    // MARK: LogsExtractor

    func extract() async throws -> Data {
        fatalError()
    }
}
