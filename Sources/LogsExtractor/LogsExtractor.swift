import Foundation

public protocol LogsExtractor {
    func extract() async throws -> Data
}
