import Foundation
import LogEntryEncryption
import LogsExtractor

public enum LogsExtractorFactory {
    public static func produce(
        secret: String,
        logsDirectoryURL: URL
    ) -> some LogsExtractor {
        let logEntryDecryptor = LogEntryDecryptor(secret: secret)

        return LogsExtractorImpl(
            logEntryDecryptor: logEntryDecryptor,
            logsDirectoryURL: logsDirectoryURL
        )
    }
}
