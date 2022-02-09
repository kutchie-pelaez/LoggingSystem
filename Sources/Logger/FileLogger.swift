final class FileLogger: Logger {
    init(provider: LoggerProvider) {
        self.provider = provider
    }

    private let provider: LoggerProvider

    // MARK: - Logger

    func log(_ entry: LogEntry) {

    }
}
