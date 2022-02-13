import Core
import Foundation

final class FileLogger: Logger {
    init(
        provider: LoggerProvider,
        composer: LogEntryComposer,
        consoleLogger: Logger?
    ) {
        self.provider = provider
        self.composer = composer
        self.consoleLogger = consoleLogger
    }

    deinit {
        try? handle?.close()
    }

    private let provider: LoggerProvider
    private let composer: LogEntryComposer
    private let consoleLogger: Logger?

    private let fileManager = FileManager.default
    private var shouldAddNewLineFirst = true

    private lazy var handle: FileHandle? = {
        let logsURL = provider.logsURL
        let logsPath = logsURL.path

        if !fileManager.fileExists(atPath: logsPath) {
            do {
                try "".write(
                    to: logsURL,
                    atomically: true,
                    encoding: .utf8
                )
                shouldAddNewLineFirst = false
            } catch {
                consoleLogger?.error(
                    "Failed to create empty logs file at \(logsPath)",
                    domain: .fileLogger
                )
                safeCrash()
            }
        }

        guard let handle = try? FileHandle(forWritingTo: logsURL) else {
            safeCrash()
            return nil
        }

        return handle
    }()

    // MARK: - Logger

    func log(_ entry: LogEntry, to target: LogTarget) {
        guard target.contains(.file) else { return }

        let message = composer.compose(entry) + "\n"

        guard let messageData = message.data(using: .utf8) else { return }

        do {
            try handle?.seekToEnd()

            if
                shouldAddNewLineFirst,
                let newLineData = "\n".data(using: .utf8)
            {
                handle?.write(newLineData)
                shouldAddNewLineFirst = false
            }

            handle?.write(messageData)
        } catch {
            consoleLogger?.error(
                """
                "Failed to write log entry to \(provider.logsURL.path)
                Error: \(error.localizedDescription)
                """,
                domain: .fileLogger
            )
            safeCrash()
        }
    }
}

extension LogDomain {
    fileprivate static let fileLogger: Self = "fileLogger"
}
