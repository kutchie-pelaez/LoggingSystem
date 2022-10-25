import Core
import CoreUtils
import Foundation
import LogEntryEncryption
import Logging
import LoggingManager
import SessionManager

final class LoggingManagerImpl<SM: SessionManager>: LoggingManager {
    private let environment: Environment
    private let logEntryEncryptor: LogEntryEncryptor
    private let logsDirectoryURL: URL
    private let sessionManager: SessionManager

    private let fileManager = FileManager.default

    private lazy var logsFileURL = logsDirectoryURL.appending(path: UUID().uuidString)
    private lazy var fileHandle: FileHandle? = {
        do {
            createLogsDirectoryifNeeded()
            createLogsFileIfNeeded()

            return try FileHandle(forWritingTo: logsFileURL)
        } catch {
            assertionFailure(error.localizedDescription)
            return nil
        }
    }()

    init(environment: Environment, logEntryEncryptor: LogEntryEncryptor, logsDirectoryURL: URL, sessionManager: SM) {
        self.environment = environment
        self.logEntryEncryptor = logEntryEncryptor
        self.logsDirectoryURL = logsDirectoryURL
        self.sessionManager = sessionManager
    }

    deinit {
        do {
            try fileHandle?.close()
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    private func createLogsDirectoryifNeeded() {
        let logsDirectoryURL = logsFileURL.deletingLastPathComponent()

        guard !fileManager.directoryExists(at: logsDirectoryURL) else { return }

        do {
            try fileManager.createDirectory(at: logsDirectoryURL)
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    private func createLogsFileIfNeeded() {
        guard !fileManager.fileExists(at: logsFileURL) else { return }

        if !fileManager.createFile(at: logsFileURL, contents: nil) {
            assertionFailure()
        }
    }

    private func makeLogHandlers(with label: String) -> [any LogHandler] {
        let fileLogHandler = {
            guard let fileHandle else {
                return Optional<FileLogHandler>.none
            }

            return FileLogHandler(
                label: label,
                logsFileURL: logsFileURL,
                fileHandle: fileHandle,
                logEntryEncryptor: logEntryEncryptor,
                sessionNumberResolver: { [weak self] in self?.sessionManager.subject.value }
            )
        }()

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
