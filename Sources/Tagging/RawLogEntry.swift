import Core

private let separator = "::"

public struct RawLogEntry: CustomStringConvertible {
    public let tag: LogEntryTag?
    public let message: String?
    public let metadata: String?

    public init(tag: LogEntryTag?, message: String?, metadata: String?) {
        self.tag = tag
        self.message = message
        self.metadata = metadata
        validateSelf()
    }

    public init(_ rawValue: String) {
        var tag: LogEntryTag?
        var message: String?
        var metadata: String?

        func proceed(_ rawValue: Substring?) {
            guard let rawValue = rawValue.map(String.init) else { return }

            if let validTag = LogEntryTag(rawValue: rawValue) {
                if tag != nil {
                    assertionFailure("Multiple tags detecteed in log entry")
                } else {
                    tag = validTag
                }
            } else if rawValue.hasPrefix("{") && rawValue.hasSuffix("}") {
                if metadata != nil {
                    assertionFailure("Multiple metadatas detecteed in log entry")
                } else {
                    metadata = rawValue
                }
            } else {
                if message != nil {
                    assertionFailure("Multiple messages detecteed in log entry")
                } else {
                    message = rawValue
                }
            }
        }

        let rawParts = rawValue.split(separator: separator, maxSplits: 3)
        proceed(rawParts[safe: 0])
        proceed(rawParts[safe: 1])
        proceed(rawParts[safe: 2])

        self.tag = tag
        self.message = message
        self.metadata = metadata
        validateSelf()
    }

    private func validateSelf() {
        assert(tag != nil || message != nil || metadata != nil)
    }

    // MARK: CustomStringConvertible

    public var description: String {
        [tag?.rawValue, message, metadata]
            .unwrapped()
            .joined(separator: separator)
    }
}
