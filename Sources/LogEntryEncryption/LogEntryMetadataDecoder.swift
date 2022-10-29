import CoreUtils
import Foundation
import Logging

public enum LogEntryMetadataDecoderError: Error {
    case jsonCastFailed(rawMetadata: String)
    case unsupportedMetadataValueType(Any)
}

public struct LogEntryMetadataDecoder {
    private let jsonDecoder = JSONDecoder()

    public init() { }

    public func decode(_ rawMetadata: String) throws-> Logger.Metadata {
        guard let data = rawMetadata.data(using: .utf8) else {
            throw ContextError(
                message: "Failed to get utf8 data",
                context: rawMetadata
            )
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LogEntryMetadataDecoderError.jsonCastFailed(
                rawMetadata: rawMetadata
            )
        }

        return try metadata(from: json)
    }

    private func metadata(from dictionary: [String: Any]) throws -> Logger.Metadata {
        try dictionary.mapValues(mapValue)
    }

    private func mapValue(_ value: Any) throws -> Logger.MetadataValue {
        switch value {
        case let dictionary as [String: Any]:
            return .dictionary(try metadata(from: dictionary))

        case let array as [Any]:
            return .array(try array.map { try mapValue($0) })

        case let string as String:
            return .string(string)

        case let stringConvertible as CustomStringConvertible:
            return .stringConvertible(stringConvertible)

        default:
            throw LogEntryMetadataDecoderError.unsupportedMetadataValueType(value)
        }
    }
}
