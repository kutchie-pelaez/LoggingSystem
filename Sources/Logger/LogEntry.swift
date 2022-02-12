public struct LogEntry {
    public enum Level {
        case log
        case warning
        case error
    }

    public init(
        message: String,
        level: Level,
        domain: LogDomain
    ) {
        self.message = message
        self.level = level
        self.domain = domain
    }

    let message: String
    let level: Level
    let domain: LogDomain
}
