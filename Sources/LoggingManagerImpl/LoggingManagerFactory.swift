import CoreUtils
import Foundation
import LogEntryEncryption
import LoggingManager
import SessionManager

public enum LoggingManagerFactory {
    public static func produce(
        environment: Environment,
        sessionManager: some SessionManager,
        provider: some LoggingManagerProvider
    ) -> some LoggingManager {
        LoggingManagerImpl(
            environment: environment,
            sessionManager: sessionManager,
            provider: provider
        )
    }

    public static func produce(
        environment: Environment,
        sessionManager: some SessionManager
    ) -> some LoggingManager {
        let provider = DefaultLoggingManagerProvider()

        return LoggingManagerImpl(
            environment: environment,
            sessionManager: sessionManager,
            provider: provider
        )
    }
}
