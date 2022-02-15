import Foundation

public protocol LogsExtractor {
    func extract() throws -> Data
}
