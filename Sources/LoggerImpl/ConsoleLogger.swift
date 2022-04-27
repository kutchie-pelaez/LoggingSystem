import Core
import Foundation
import Logger

private let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HH:mm:ss"
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

    return dateFormatter
}()

struct ConsoleLogger: Logger {
    init?(environment: Environment) {
        guard environment.isDev else { return nil }
    }

    // MARK: - Logger

    func log(_ entry: LoggingEntry, to target: LoggingTarget) {
        guard target.contains(.console) else { return }

        let datePart = dateFormatter.string(from: .now).braced
        let domainPart = entry.domain.name.braced
        let levelPart = entry.level.symbol

        let message = [
            datePart,
            domainPart,
            levelPart,
            entry.message
        ].unwrapped().joined(separator: " ")

        print(message)
    }
}

extension String {
    fileprivate var braced: String { "[\(self)]" }
}
