import Foundation
import LogEncryption
import LogsExtractor

public enum LogsExtractorFactory {
    public static func produce(
        secret: String,
        logsDirectoryURL: URL
    ) -> some LogsExtractor {
        let decoder = LogDecoder(secret: secret)
        let encoder = LogEncoder(secret: secret)

        return LogsExtractorImpl(
            decoder: decoder,
            encoder: encoder,
            logsDirectoryURL: logsDirectoryURL
        )
    }
}
