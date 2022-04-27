import Core
import Foundation
import Logger
import SessionManager

private let logEnrtyTimeDateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US")
    dateFormatter.dateFormat = "HH:mm:ss"
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

    return dateFormatter
}()

private let sessionEndingDayDateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US")
    dateFormatter.dateFormat = "MMMM d"
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

    return dateFormatter
}()

final class FileLogger: Logger {
    private let provider: LoggerProvider
    private let sessionManager: SessionManager
    private let currentDateResolver: Resolver<Date>

    private lazy var writer: FileLoggerWriter = {
        let sessionParams = [
            "Date: \(sessionEndingDayDateFormatter.string(from: currentDateResolver()))",
            "Session: \(sessionManager.sessionValueSubject.value)"
        ] + provider.sessionAdditionalParams

        return FileLoggerWriterImpl(
            logsURL: provider.logsURL,
            sessionParams: sessionParams
        )
    }()

    init(
        provider: LoggerProvider,
        sessionManager: SessionManager,
        currentDateResolver: @escaping Resolver<Date> = { .now }
    ) {
        self.provider = provider
        self.sessionManager = sessionManager
        self.currentDateResolver = currentDateResolver
        setInitialState()
    }

    private func setInitialState() {
        let url = provider.logsURL

        if
            FileManager.default.fileExists(atPath: url.path) &&
            (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) != 0
        {
            writer.writeNewLine()
        } else {
            do {
                try "".write(to: url, atomically: true, encoding: .utf8)
            } catch {
                assertionFailure("Failed to create empty logs file at \(url.path)")
            }
        }

        writer.writeHeader()
    }

    private func appendLevelIndicatorIfNeeded(to message: inout String, from entry: LoggingEntry) {
        guard
            let symbol = entry.level.symbol,
            let file = entry.file,
            let function = entry.function,
            let line = entry.line
        else {
            return
        }

        let filename = file.split(separator: "/")
            .last
            .orEmpty
            .replacing(".swift", with: "")

        message.append(" \(symbol) \(filename)::\(function) \(line)")
    }

    // MARK: - Logger

    func log(_ entry: LoggingEntry, to target: LoggingTarget) {
        guard target.contains(.file) else { return }

        writer.updateWidestDomainIfNeeded(entry.domain.name)
        writer.updateWidestMessageIfNeeded(entry.message)

        let date = logEnrtyTimeDateFormatter.string(from: currentDateResolver())
        let domain = entry.domain.name
        var message = "| \(date) [\(domain)]   \(entry.message) |"
        appendLevelIndicatorIfNeeded(to: &message, from: entry)

        writer.writeMessage(message)
    }
}
