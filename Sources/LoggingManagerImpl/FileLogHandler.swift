import Core
import Foundation
import Logging

struct FileLogHandler: LogHandler {
    private let logsFileURL: URL

    private lazy var fileHandle: FileHandle? = {
        do {
            return try FileHandle(forWritingTo: logsFileURL)
        } catch {
            assertionFailure(error.localizedDescription)
            return nil
        }
    }()

    init(logsFileURL: URL) {
        self.logsFileURL = logsFileURL
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

        if fileManager.createFile(at: logsFileURL, contents: nil) {
            assertionFailure()
        }
    }

    // MARK: LogHandler

    var metadata: Logger.Metadata = [:]

    var logLevel: Logger.Level = .trace

    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
        createLogsDirectoryifNeeded()
        createLogsFileIfNeeded()
    }
}

private var fileManager: FileManager { .default }
