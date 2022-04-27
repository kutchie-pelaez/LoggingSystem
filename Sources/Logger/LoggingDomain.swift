public struct LoggingDomain: ExpressibleByStringLiteral, CustomStringConvertible {
    public let name: String

    // MARK: - ExpressibleByStringLiteral

    public init(stringLiteral value: StringLiteralType) {
        self.name = value
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        name
    }
}
