public struct LoggingEntry {
    public enum Level {
        case log
        case warning
        case error
    }

    public let message: String
    public let level: Level
    public let domain: LoggingDomain
    public let file: String?
    public let function: String?
    public let line: Int?

    public init(
        message: String,
        level: Level,
        domain: LoggingDomain
    ) {
        self.message = message
        self.level = level
        self.domain = domain
        self.file = nil
        self.function = nil
        self.line = nil
    }

    init(
        message: String,
        level: Level,
        domain: LoggingDomain,
        file: String?,
        function: String?,
        line: Int
    ) {
        self.message = message
        self.level = level
        self.domain = domain
        self.file = file
        self.function = function
        self.line = line
    }
}
