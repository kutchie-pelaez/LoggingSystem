import Core
import Foundation
import LogsExtractor

public enum LogsExtractorFactory {
    public static func produce(provider: some LogsExtractorProvider) -> some LogsExtractor {
        LogsExtractorImpl(provider: provider)
    }

    public static func produce() -> some LogsExtractor {
        let provider = DefaultLogsExtractorProvider()

        return produce(provider: provider)
    }
}
