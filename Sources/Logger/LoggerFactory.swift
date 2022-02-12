import Core

public struct LoggerFactory {
    public init() { }

    public func produce(
        environment: Environment,
        provider: LoggerProvider
    ) -> Logger {
        let logEntryComposer = LogEntryComposerImpl()
        let consoleLogger = ConsoleLogger(
            environment: environment,
            composer: logEntryComposer
        )
        let fileLogger = FileLogger(
            provider: provider,
            composer: logEntryComposer,
            consoleLogger: consoleLogger
        )

        return LoggerImpl(
            loggers: [
                consoleLogger,
                fileLogger
            ].unwrapped()
        )
    }
}
