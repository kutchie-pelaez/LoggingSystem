import Core
import CoreUtils
import Foundation
import LogEntryEncryption
import Logging
import LoggingManager
import SessionManager

final class LoggingManagerImpl<
    SM: SessionManager,
    LMP: LoggingManagerProvider
>: LoggingManager, FileLogHandlerDelegate {
    private let environment: Environment
    private let sessionManager: SM
    private let provider: LMP

    private let fileManager = FileManager.default
    private let logsFileName = UUID().uuidString + ".kplogs"
    private var isHeaderWritten = false

    private lazy var logsFileURL = provider.logsFileURL(for: logsFileName)
    private lazy var fileHandle: FileHandle? = {
        do {
            try createLogsDirectoryifNeeded()
            try createLogsFileIfNeeded()

            return try FileHandle(forWritingTo: logsFileURL)
        } catch {
            assertionFailure(error.localizedDescription)
            return nil
        }
    }()

    init(environment: Environment, sessionManager: SM, provider: LMP) {
        self.environment = environment
        self.sessionManager = sessionManager
        self.provider = provider
    }

    deinit {
        do {
            try fileHandle?.close()
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    private func createLogsDirectoryifNeeded() throws {
        let logsDirectoryURL = logsFileURL.deletingLastPathComponent()

        guard !fileManager.directoryExists(at: logsDirectoryURL) else { return }

        try fileManager.createDirectory(at: logsDirectoryURL)
    }

    private func createLogsFileIfNeeded() throws {
        guard !fileManager.fileExists(at: logsFileURL) else { return }

        try fileManager.createFile(at: logsFileURL, contents: nil)
    }

    private func makeLogHandlers(with label: String) -> [any LogHandler] {
        let loggerType = LoggerType(from: label)

        let fileLogHandler = {
            guard let fileHandle else {
                return Optional<FileLogHandler>.none
            }

            var fileLogHandler = FileLogHandler(
                label: label,
                loggerType: loggerType,
                fileHandle: fileHandle,
                logEntryEncryptor: provider.encryptionKey.map(LogEntryEncryptor.init),
                sessionNumber: sessionManager.subject.value,
                shouldWriteHeader: { [weak self] in
                    guard let self else { return false }

                    return !self.isHeaderWritten
                }
            )
            fileLogHandler.delegate = self

            return fileLogHandler
        }()

        let stdoutLogHandler = {
            guard environment == .dev else {
                return Optional<StdoutLogHandler>.none
            }

            return StdoutLogHandler(
                label: label,
                loggerType: loggerType
            )
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

    // MARK: FileLogHandlerDelegate

    func fileLogHandlerDidWriteHeader() {
        isHeaderWritten = true
    }
}
