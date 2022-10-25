import CoreUtils
import Foundation
import LogEntryEncryption
import LoggingManager
import SessionManager

public enum LoggerFactory {
    public static func produce(
        environment: Environment,
        secret: String,
        logsDirectoryURL: URL,
        sessionManager: some SessionManager
    ) -> some LoggingManager {
        let logEntryEncryptor = LogEntryEncryptor(secret: secret)

        return LoggingManagerImpl(
            environment: environment,
            logEntryEncryptor: logEntryEncryptor,
            logsDirectoryURL: logsDirectoryURL,
            sessionManager: sessionManager
        )
    }
}
