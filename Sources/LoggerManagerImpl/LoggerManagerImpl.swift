import Core
import CoreUtils
import Encryption
import Foundation
import LoggerManager
import Logging
import SessionManager
import Tagging

final class LoggerManagerImpl<
    SM: SessionManager,
    LMP: LoggerManagerProvider
>: LoggerManager, FileLogHandlerDelegate {
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
        do { try fileHandle?.close() }
        catch { assertionFailure(error.localizedDescription) }
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
        let type = LoggerType(from: label)

        let fileLogHandler = {
            guard let fileHandle = fileHandle else {
                return Optional<FileLogHandler>.none
            }

            var fileLogHandler = FileLogHandler(
                type: type,
                fileHandle: fileHandle,
                logEntryEncryptor: provider.encryptionKey.map(LogEntryEncryptor.init),
                sessionNumber: sessionManager.sessionNumber,
                shouldWriteHeader: { [weak self] in self?.isHeaderWritten == false }
            )
            fileLogHandler.delegate = self

            return fileLogHandler
        }()

        let stdoutLogHandler = {
            guard environment == .dev else {
                return Optional<StdoutLogHandler>.none
            }

            return StdoutLogHandler(type: type)
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
