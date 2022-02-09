import Foundation
import Logs

final class LogsComposerImpl: LogsComposer {
    init(provider: LogsComposerProvider) {
        self.provider = provider
    }

    private let provider: LogsComposerProvider

    // MARK: - LogsComposer

    func compose() throws -> Data {
        fatalError()
    }
}
