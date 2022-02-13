public struct LogTarget: OptionSet {
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public let rawValue: Int

    public static let console = LogTarget(rawValue: 1 << 0)
    public static let file = LogTarget(rawValue: 1 << 1)

    public static let all: LogTarget = [.console, .file]
}
