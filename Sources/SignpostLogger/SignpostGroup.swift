public struct SignpostGroup: RawRepresentable, ExpressibleByStringInterpolation {
    public static let screen: SignpostGroup = "screen"
    public static let network: SignpostGroup = "network"
    public static let applicationState: SignpostGroup = "applicationState"

    public var rawValue: String

    public init?(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringInterpolation: String) {
        self.rawValue = stringInterpolation
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}
