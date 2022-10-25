import Core
import CoreUtils
import Foundation
import LogCoding
import Logging
import LoggingManager
import SessionManager

final class LoggingManagerImpl<SM: SessionManager>: LoggingManager {
    private let environment: Environment
    private let encoder: LogEncoder
    private let sessionManager: SessionManager

    private let logsFileName = UUID().uuidString

    init(environment: Environment, encoder: LogEncoder, sessionManager: SM) {
        self.environment = environment
        self.encoder = encoder
        self.sessionManager = sessionManager
    }

    private func makeLogHandlers(with label: String) -> [any LogHandler] {
        let logsDirectoryURL = FileManager.default.documents.appending(path: "logs")
        let logsFileURL = logsDirectoryURL.appending(path: logsFileName)
        let fileLogHandler = FileLogHandler(
            label: label,
            logsFileURL: logsFileURL,
            encoder: encoder,
            sessionNumberResolver: { [weak self] in self?.sessionManager.subject.value }
        )

        let stdoutLogHandler = {
            guard environment == .dev else {
                return Optional<StdoutLogHandler>.none
            }

            return StdoutLogHandler(label: label)
        }()

        return [fileLogHandler, stdoutLogHandler].unwrapped()
    }

    // MARK: Startable

    func start() {
        LoggingSystem.bootstrap { [weak self] label in
            guard let logHandlers = self?.makeLogHandlers(with: label) else {
                return SwiftLogNoOpLogHandler()
            }

            return MultiplexLogHandler(logHandlers)
        }
    }
}
