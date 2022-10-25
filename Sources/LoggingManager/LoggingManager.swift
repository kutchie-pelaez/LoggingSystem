import CoreUtils
import Foundation

public protocol LoggingManager: Startable {
    func extractLogs() throws -> Data
}
