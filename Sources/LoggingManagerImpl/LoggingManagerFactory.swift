import CoreUtils
import LoggingManager
import SessionManager

public enum LoggerFactory {
    public static func produce(
        environment: Environment,
        secret: String,
        sessionManager: some SessionManager
    ) -> some LoggingManager {
        LoggingManagerImpl(
            environment: environment,
            secret: secret,
            sessionManager: sessionManager
        )
    }
}
