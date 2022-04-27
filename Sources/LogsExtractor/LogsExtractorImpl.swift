import Foundation

final class LogsExtractorImpl: LogsExtractor {
    private let provider: LogsExtractorProvider

    init(provider: LogsExtractorProvider) {
        self.provider = provider
    }

    // MARK: - LogsComposer

    func extract() throws -> Data {
        try Data(contentsOf: provider.logsURL)
    }
}
