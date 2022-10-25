import Foundation
import LogCoding
import LogsExtractor

final class LogsExtractorImpl: LogsExtractor {
    private let decoder: LogDecoder
    private let encoder: LogEncoder

    init(decoder: LogDecoder, encoder: LogEncoder) {
        self.decoder = decoder
        self.encoder = encoder
    }

    func extract() async throws -> Data {
        fatalError()
    }
}
