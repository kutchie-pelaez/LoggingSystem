import Core
import Foundation
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
    init(
        provider: LoggerProvider,
        sessionManager: SessionManager,
        consoleLogger: Logger?,
        currentDateResolver: @escaping Resolver<Date> = { .now }
    ) {
        self.provider = provider
        self.sessionManager = sessionManager
        self.consoleLogger = consoleLogger
        self.currentDateResolver = currentDateResolver
        startDate = currentDateResolver()
        createEmptyLogsFileIfNeeded(at: provider.logsURL)
    }

    deinit {
        try? handle?.close()
    }

    private let provider: LoggerProvider
    private let sessionManager: SessionManager
    private let consoleLogger: Logger?
    private let currentDateResolver: Resolver<Date>

    private let fileManager = FileManager.default

    private var sessionParams: [String] {
        [
            "Date: \(sessionEndingDayDateFormatter.string(from: currentDateResolver()))",
            "Session: \(sessionManager.session)",
            "Time spent: \(hoursDiff):\(minutesDiff):\(secondsDiff)",
        ] + provider.sessionAdditionalParams
    }

    // MARK: - Diff

    private let startDate: Date
    private var timeDiffComponents: DateComponents {
        Calendar.current.dateComponents(
            [.hour, .minute, .second],
            from: startDate,
            to: currentDateResolver()
        )
    }
    private var hoursDiff: String {
        guard let hour = timeDiffComponents.hour else { return "00" }

        return hour < 10 ? "0" + String(hour) : String(hour)
    }
    private var minutesDiff: String {
        guard let minute = timeDiffComponents.minute else { return "00" }

        return minute < 10 ? "0" + String(minute) : String(minute)
    }
    private var secondsDiff: String {
        guard let second = timeDiffComponents.second else { return "00" }

        return second < 10 ? "0" + String(second) : String(second)
    }

    // MARK: - Handle

    private lazy var handle: FileHandle? = {
        let logsURL = provider.logsURL

        guard let handle = try? FileHandle(forWritingTo: logsURL) else {
            safeCrash()
            return nil
        }

        return handle
    }()

    private func createEmptyLogsFileIfNeeded(at url: URL) {
        if fileManager.fileExists(atPath: url.path) {
            let attributes = try? fileManager.attributesOfItem(atPath: url.path)
            if (attributes?[.size] as? Int) != 0 {
                write("\n\n")
            }
        } else {
            do {
                try "".write(
                    to: url,
                    atomically: true,
                    encoding: .utf8
                )
            } catch {
                print(error)
                consoleLogger?.error(
                    "Failed to create empty logs file at \(url.path)",
                    domain: .fileLogger
                )
                safeCrash()
            }
        }

        writeEmptyBoxTopBound()
    }

    // MARK: - Writing

    private func write(_ string: String, offset: UInt64? = nil) {
        do {
            if let offset = offset {
                try handle?.seek(toOffset: offset)
            } else {
                try handle?.seekToEnd()
            }

            try handle?.write(contentsOf: string.utf8Data)
        } catch {
            safeCrash("Failed to write \(string) string \(offset.isNil ? "to the end of logs" : "with \(offset!) offset")")
        }
    }

    private func footerWidth(from params: [String]) -> Int {
        safeUndefinedIfNil(
            params
                .map(\.count)
                .map { 2 + $0 + 2 }
                .max()!,
            0
        )
    }

    private func space(_ count: Int) -> String {
        repeating(" ", count)
    }

    private func line(_ count: Int) -> String {
        repeating("─", count)
    }

    private func repeating(_ string: String, _ count: Int) -> String {
        Array(
            repeating: string,
            count: count
        ).joined()
    }

    private var widestDomain: String?
    private var widestMessage: String?

    private var boxTopLineOffset: UInt64?
    private var boxCurrentTopLineWidth = 2

    private func writeEmptyBoxTopBound() {
        write("╭")
        boxTopLineOffset = try? handle?.offset()
        write("╮")
        write("\n")
    }

    private var boxWidth: Int {
        1 + // left bound
        1 + // space
        8 + // time
        1 + // space
        1 + // bracket
        widestDomain.orEmpty.count +
        1 + // bracket
        3 + // space
        widestMessage.orEmpty.count +
        1 + // space
        1 // right bound
    }

    private func updateBoxTopBound() {
        guard
            let boxTopLineOffset = boxTopLineOffset,
            boxCurrentTopLineWidth < boxWidth
        else {
            return
        }

        write(
            line(boxWidth - boxCurrentTopLineWidth),
            offset: boxTopLineOffset
        )
    }

    private func updateMessagesAlignment() {

    }

    private func updateBoxRightBoundAlignment() {

    }

    private func writeBoxBottomBound() {
        let footerWidth = footerWidth(from: sessionParams)

        write("├")
        write(line(footerWidth - 2))
        write("┬")
        write(line(boxWidth - footerWidth - 1))
        write("╯")
        write("\n")
    }

    private func writeFooter() {
        let params = sessionParams
        let footerWidth = footerWidth(from: params)

        for param in params {
            var line = "│"
            line.append(space(1))
            line.append(param)
            line.append(space(footerWidth - 2 - param.count - 1))
            line.append("│")
            write(line)
            write("\n")
        }

        let footerBottomLine = "╰" + line(footerWidth - 2) + "╯"
        write(footerBottomLine)
    }

    // MARK: - Logger

    func log(_ entry: LogEntry, to target: LogTarget) {
        guard target.contains(.file) else { return }

        if
            widestDomain.isNil ||
            entry.domain.name.count > widestDomain!.count
        {
            widestDomain = entry.domain.name
        }

        if
            widestMessage.isNil ||
            entry.message.count > widestMessage!.count
        {
            widestMessage = entry.message
        }

        let message = "│" +
            " " +
            logEnrtyTimeDateFormatter.string(from: currentDateResolver()) +
            " " +
            "[" +
            entry.domain.name +
            "]" +
            " " +
            entry.message +
            " " +
            "│"

        write(message)
        write("\n")
    }

    func finish() {
        writeBoxBottomBound()
        writeFooter()
    }
}

extension LogDomain {
    fileprivate static let fileLogger: Self = "fileLogger"
}
