import Foundation
import LogsExtractor

final class LogsExtractorImpl: LogsExtractor {
    private let secret: String

    init(secret: String) {
        self.secret = secret
    }

    func extract() async throws -> Data {
        fatalError()
    }
}
