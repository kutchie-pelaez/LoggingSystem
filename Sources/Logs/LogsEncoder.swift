import Core
import Foundation
import Yams

public struct LogsEncoder {
    public init() { }

    private let encoder = YAMLEncoder()

    public func encode(_ logs: Logs) throws -> Data {
        let ymlString = try encoder.encode(logs)

        return ymlString.utf8Data
    }
}
