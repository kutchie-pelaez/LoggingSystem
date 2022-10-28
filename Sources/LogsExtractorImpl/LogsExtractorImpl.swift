import Core
import CoreUtils
import Foundation
import LogEntryEncryption
import LogsExtractor

let logsExtractorQueue = DispatchQueue(label: "com.kutchie-pelaez.LogsExtractor")

final class LogsExtractorImpl<LEP: LogsExtractorProvider>: LogsExtractor {
    private let provider: LogsExtractorProvider

    init(provider: LEP) {
        self.provider = provider
    }

    // MARK: LogsExtractor

    func extract() async throws -> URL {
        let fileManager = FileManager.default
        let rawLogs = try await provider.rawLogs()
        let extractedLogsFileURL = fileManager
            .temporaryDirectory
            .appending(path: "logs.kplogs")

        try await withCheckedThrowingContinuation { continuation in
            var combinedLogsString = ""

            dispatch(to: logsExtractorQueue) {
                do {
                    for logsData in rawLogs {
                        guard let rawLogString = String(data: logsData, encoding: .utf8) else {
                            throw ContextError(
                                message: "Failed to create utf8 encoded logs srting",
                                context: logsData
                            )
                        }

                        combinedLogsString += rawLogString
                            .split(separator: "\n")
                            .joined(separator: "\n")
                    }
                    let combinedLogsData = combinedLogsString.data(using: .utf8)
                    try FileManager.default.createFile(
                        at: extractedLogsFileURL,
                        contents: combinedLogsData,
                        overwrite: true
                    )

                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }

        return extractedLogsFileURL
    }
}
