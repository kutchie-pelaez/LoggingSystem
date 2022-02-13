import Foundation

private let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd.MM.yy HH:mm:ss"
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

    return dateFormatter
}()

protocol LogEntryComposer {
    func compose(_ entry: LogEntry) -> String
}

struct LogEntryComposerImpl: LogEntryComposer {
    func compose(_ entry: LogEntry) -> String {
        let datePart = dateFormatter.string(from: .now).braced
        let domainPart = entry.domain.name.braced
        let levelPart = entry.level.symbol

        return [
            datePart,
            domainPart,
            levelPart,
            entry.message
        ].unwrapped().joined(separator: " ")
    }
}

extension LogEntry.Level {
    fileprivate var symbol: String? {
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

extension String {
    fileprivate var braced: String {
        "[\(self)]"
    }
}
