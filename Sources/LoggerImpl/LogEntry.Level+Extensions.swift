import Logger

extension LoggingEntry.Level {
    var symbol: String? {
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
