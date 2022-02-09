final class LoggerImpl: Logger {
    init(loggers: [Logger]) {
        self.loggers = loggers
    }

    private let loggers: [Logger]

    // MARK: - Logger

    func log(_ entry: LogEntry) {
        loggers.forEach { $0.log(entry) }
    }
}
