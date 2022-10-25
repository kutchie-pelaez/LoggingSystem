import Core
import Foundation
import LogCoding
import Logging

struct FileLogHandler: LogHandler {
    private let label: String
    private let logsFileURL: URL
    private let encoder: LogEncoder
    private let sessionNumberResolver: Resolver<Int?>

    private lazy var fileHandle: FileHandle? = {
        do {
            return try FileHandle(forWritingTo: logsFileURL)
        } catch {
            assertionFailure(error.localizedDescription)
            return nil
        }
    }()

    init(
        label: String,
        logsFileURL: URL,
        encoder: LogEncoder,
        sessionNumberResolver: @escaping Resolver<Int?>
    ) {
        self.label = label
        self.logsFileURL = logsFileURL
        self.encoder = encoder
        self.sessionNumberResolver = sessionNumberResolver
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

    private func fullMetadata(
        merging metadataToMerge: Logger.Metadata?,
        level: Logger.Level,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) -> Logger.Metadata {
        var additionalMetadata: Logger.Metadata = [
            "label": "\(label)",
            "level": "\(level)",
            "module": "\(source)",
            "function": "\(function)",
            "line": "\(line)"
        ]
        if let fileLastComponent = file.split(separator: "/").last {
            additionalMetadata["file"] = "\(fileLastComponent)"
        }
        if let sessionNumber = sessionNumberResolver() {
            additionalMetadata["sessionNumber"] = "\(sessionNumber)"
        }

        return additionalMetadata
            .appending(self.metadata)
            .appending(metadataToMerge)
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

        let _ = fullMetadata(merging: metadata, level: level, source: source, file: file, function: function, line: line)
    }
}

private var fileManager: FileManager { .default }
