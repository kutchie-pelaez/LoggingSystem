import CoreUtils
import Foundation
import LogEncryption
import LoggingManager
import SessionManager

public enum LoggerFactory {
    public static func produce(
        environment: Environment,
        secret: String,
        logsDirectoryURL: URL,
        sessionManager: some SessionManager
    ) -> some LoggingManager {
        let logEncryptor = LogEncryptor(secret: secret)

        return LoggingManagerImpl(
            environment: environment,
            logEncryptor: logEncryptor,
            logsDirectoryURL: logsDirectoryURL,
            sessionManager: sessionManager
        )
    }
}
