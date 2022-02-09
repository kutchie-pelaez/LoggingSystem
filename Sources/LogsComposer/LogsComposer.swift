import Foundation

public protocol LogsComposer {
    func compose() throws -> Data
}
