public struct LoggingTarget: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let console = LoggingTarget(rawValue: 1 << 0)
    public static let file = LoggingTarget(rawValue: 1 << 1)

    public static let all: LoggingTarget = [.console, .file]
}
