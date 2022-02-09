import Core

public struct LoggerFactory {
    public init() { }

    public func produce(
        environment: Environment,
        provider: LoggerProvider
    ) -> Logger {
        let consoleLogger = ConsoleLogger(environment: environment)
        let fileLogger = FileLogger(provider: provider)

        return LoggerImpl(
            loggers: [
                consoleLogger,
                fileLogger
            ].unwrapped()
        )
    }
}
