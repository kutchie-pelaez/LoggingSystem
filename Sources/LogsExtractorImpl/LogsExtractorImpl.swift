import Foundation
import LogEntryEncryption
import LogsExtractor

final class LogsExtractorImpl: LogsExtractor {
    private let logEntryDecryptor: LogEntryDecryptor
    private let logsDirectoryURL: URL

    init(logEntryDecryptor: LogEntryDecryptor, logsDirectoryURL: URL) {
        self.logEntryDecryptor = logEntryDecryptor
        self.logsDirectoryURL = logsDirectoryURL
    }

    // MARK: LogsExtractor

    func extract() async throws -> Data {
        fatalError()
    }
}
