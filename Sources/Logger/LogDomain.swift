public struct LogDomain: ExpressibleByStringLiteral, CustomStringConvertible {
    let name: String

    // MARK: - ExpressibleByStringLiteral

    public init(stringLiteral value: StringLiteralType) {
        self.name = value
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        name
    }
}
