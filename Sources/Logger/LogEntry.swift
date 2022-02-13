public struct LogEntry {
    public enum Level {
        case log
        case warning
        case error

        internal var symbol: String? {
            switch self {
            case .log:
                return nil

            case .warning:
                return "🟡"

            case .error:
                return "🔴"
            }
        }
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
