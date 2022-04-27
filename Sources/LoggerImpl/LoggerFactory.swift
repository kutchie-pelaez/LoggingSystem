import Core
import Logger
import SessionManager

public struct LoggerFactory {
    public init() { }

    public func produce(
        environment: Environment,
        sessionManager: SessionManager,
        provider: LoggerProvider
    ) -> Logger {
        let consoleLogger = ConsoleLogger(
            environment: environment
        )
        let fileLogger = FileLogger(
            provider: provider,
            sessionManager: sessionManager
        )

        return LoggerImpl(
            loggers: [
                consoleLogger,
                fileLogger
            ].unwrapped()
        )
    }
}
