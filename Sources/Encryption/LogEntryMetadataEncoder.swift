import CoreUtils
import Foundation
import Logging

public struct LogEntryMetadataEncoder {
    private let jsonEncoder = JSONEncoder()

    public init() { }

    public func encode(_ metadata: Logger.Metadata) throws -> String {
        let encodableWrapper = MetadataValueEncodableWrapper(metadataValue: .dictionary(metadata))
        let data = try jsonEncoder.encode(encodableWrapper)

        guard let string = String(data: data, encoding: .utf8) else {
            throw ContextError(
                message: "Failed to get utf8 string from metadata",
                context: data
            )
        }

        return string
    }
}

private struct MetadataValueEncodableWrapper: Encodable {
    private struct StringCodingKey: CodingKey {
        var stringValue: String
        var intValue: Int?

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            return nil
        }
    }

    private let metadataValue: Logger.MetadataValue

    init(metadataValue: Logger.MetadataValue) {
        self.metadataValue = metadataValue
    }

    // MARK: Encodable

    func encode(to encoder: Encoder) throws {
        func encodeSingleValue(_ singleValue: some Encodable) throws {
            var container = encoder.singleValueContainer()
            try container.encode(singleValue)
        }

        switch metadataValue {
        case .string(let string):
            try encodeSingleValue(string)

        case .stringConvertible(let stringConvertible):
            try encodeSingleValue(stringConvertible.description)

        case .dictionary(let dictionary):
            var container = encoder.container(keyedBy: StringCodingKey.self)
            for (key, value) in dictionary.sorted(by: { $0.key < $1.key }) {
                guard let key = StringCodingKey(stringValue: key) else { continue }

                let encodableWrapper = MetadataValueEncodableWrapper(metadataValue: value)
                try container.encode(encodableWrapper, forKey: key)
            }

        case .array(let array):
            let singleValue = array.map(MetadataValueEncodableWrapper.init)
            try encodeSingleValue(singleValue)
        }
    }
}
