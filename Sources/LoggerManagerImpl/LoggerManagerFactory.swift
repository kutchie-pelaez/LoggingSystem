import CoreUtils
import Encryption
import Foundation
import LoggerManager
import SessionManager

public enum LoggerManagerFactory {
    public static func produce(
        environment: Environment,
        sessionManager: some SessionManager,
        provider: some LoggerManagerProvider
    ) -> some LoggerManager {
        LoggerManagerImpl(
            environment: environment,
            sessionManager: sessionManager,
            provider: provider
        )
    }

    public static func produce(
        environment: Environment,
        sessionManager: some SessionManager
    ) -> some LoggerManager {
        let provider = DefaultLoggerManagerProvider()

        return produce(
            environment: environment,
            sessionManager: sessionManager,
            provider: provider
        )
    }
}
