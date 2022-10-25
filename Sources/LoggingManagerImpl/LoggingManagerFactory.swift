import CoreUtils
import LogCoding
import LoggingManager
import SessionManager

public enum LoggerFactory {
    public static func produce(
        environment: Environment,
        secret: String,
        sessionManager: some SessionManager
    ) -> some LoggingManager {
        let encoder = LogEncoder(secret: secret)

        return LoggingManagerImpl(
            environment: environment,
            encoder: encoder,
            sessionManager: sessionManager
        )
    }
}
