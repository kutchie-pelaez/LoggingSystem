import Core

final class ConsoleLogger: Logger {
    init?(environment: Environment) {
        guard environment.isDev else { return nil }
    }

    // MARK: - Logger

    func log(_ entry: LogEntry) {

    }

    func error(_ entry: LogEntry) {

    }

    func warning(_ entry: LogEntry) {

    }
}
