import Foundation

final class LogsExtractorImpl: LogsExtractor {
    init(provider: LogsExtractorProvider) {
        self.provider = provider
    }

    private let provider: LogsExtractorProvider

    // MARK: - LogsComposer

    func extract() throws -> Data {
        try Data(contentsOf: provider.logsURL)
    }
}
