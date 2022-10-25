import Foundation
import LogCoding
import LogsExtractor

final class LogsExtractorImpl: LogsExtractor {
    private let decoder: LogDecoder
    private let encoder: LogEncoder
    private let logsDirectoryURL: URL

    init(decoder: LogDecoder, encoder: LogEncoder, logsDirectoryURL: URL) {
        self.decoder = decoder
        self.encoder = encoder
        self.logsDirectoryURL = logsDirectoryURL
    }

    func extract() async throws -> Data {
        fatalError()
    }
}
