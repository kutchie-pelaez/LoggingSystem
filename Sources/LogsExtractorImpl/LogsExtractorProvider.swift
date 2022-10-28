import Core
import CoreUtils
import Foundation

public protocol LogsExtractorProvider {
    func rawLogs() async throws -> [Data]
}

struct DefaultLogsExtractorProvider: LogsExtractorProvider {
    func rawLogs() async throws -> [Data] {
        let fileManager = FileManager.default
        let logsDirectoryURL = fileManager.documents.appending(path: "logs")
        let fileURLs = try fileManager.items(at: logsDirectoryURL)

        async let files = try fileURLs
            .sorted { lhs, rhs in
                guard let lhsCreationDate = lhs.creationDate, let rhsCreationDate = rhs.creationDate else {
                    throw ContextError(
                        message: "Failed to access creationDate resource value",
                        context: [lhs, rhs]
                    )
                }

                return lhsCreationDate < rhsCreationDate
            }
            .asyncMap { fileURL in
                try await withCheckedThrowingContinuation { continuation in
                    dispatch(to: logsExtractorQueue) {
                        do {
                            let data = try Data(contentsOf: fileURL)
                            continuation.resume(returning: data)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }

        return try await files
    }
}
