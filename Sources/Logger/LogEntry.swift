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
        self.file = nil
        self.function = nil
        self.line = nil
    }

    internal init(
        message: String,
        level: Level,
        domain: LogDomain,
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

    let message: String
    let level: Level
    let domain: LogDomain
    let file: String?
    let function: String?
    let line: Int?
}
