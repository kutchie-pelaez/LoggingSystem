import CoreUtils
import Foundation
import LogCoding
import LoggingManager
import SessionManager

public enum LoggerFactory {
    public static func produce(
        environment: Environment,
        secret: String,
        logsDirectoryURL: URL,
        sessionManager: some SessionManager
    ) -> some LoggingManager {
        let encoder = LogEncoder(secret: secret)

        return LoggingManagerImpl(
            environment: environment,
            encoder: encoder,
            logsDirectoryURL: logsDirectoryURL,
            sessionManager: sessionManager
        )
    }
}
