import Logger

struct LoggerImpl: Logger {
    private let loggers: [Logger]

    init(loggers: [Logger]) {
        self.loggers = loggers
    }

    // MARK: - Logger

    func log(_ entry: LoggingEntry, to target: LoggingTarget) {
        loggers.forEach { $0.log(entry, to: target) }
    }
}
