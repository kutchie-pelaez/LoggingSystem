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
        try? readingHandle?.close()
        try? writingHandle?.close()
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

    // MARK: - Handles

    private lazy var readingHandle: FileHandle? = {
        safeUndefinedIfNil(
            try? FileHandle(forReadingFrom: provider.logsURL),
            nil
        )
    }()

    private lazy var writingHandle: FileHandle? = {
        safeUndefinedIfNil(
            try? FileHandle(forWritingTo: provider.logsURL),
            nil
        )
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
                consoleLogger?.error(
                    "Failed to create empty logs file at \(url.path)",
                    domain: .fileLogger
                )
                safeCrash()
            }
        }

        startOffset = try? writingHandle?.offset()
        write(boxTopBound)
        write("\n")
    }

    // MARK: - Writing

    private func write(_ string: String, offset: UInt64? = nil) {
        do {
            if let offset = offset {
                try writingHandle?.seek(toOffset: offset)
            } else {
                try writingHandle?.seekToEnd()
            }

            try writingHandle?.write(contentsOf: string.utf8Data)
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

    private func filename(from file: String) -> String {
        file.split(separator: "/")
            .last
            .orEmpty
            .replacingOccurrences(
                of: ".swift",
                with: ""
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

    private var startOffset: UInt64?
    private var boxCurrentTopLineWidth = 2

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

    private var boxTopBound: String {
        "╭" + line(boxWidth - 2) + "╮"
    }

    private func syncAlignment() {
        guard let startOffset = startOffset else {
            return
        }

        try? readingHandle?.seek(toOffset: startOffset)

        guard
            let currentData = try? readingHandle?.readToEnd(),
            let currentString = String(data: currentData, encoding: .utf8)
        else {
            return
        }

        let currentLines = currentString
            .split(separator: "\n")
            .map(String.init)
        var newLines = [String]()

        for var currentLine in currentLines {
            if currentLine.starts(with: "╭") {
                newLines.append(boxTopBound)
            } else {
                domainAlignment:
                do {
                    guard
                        let widestDomain = widestDomain,
                        let domainOpeningBracketIndex = currentLine.firstIndex(of: "["),
                        let domainClosingBracketIndex = currentLine.firstIndex(of: "]")
                    else {
                        break domainAlignment
                    }

                    let currentDomain = currentLine[
                        currentLine.index(after: domainOpeningBracketIndex)
                        ...
                        currentLine.index(before: domainClosingBracketIndex)
                    ]

                    let diff = widestDomain.count - currentDomain.count
                    if diff > 0 {
                        let requiredNumberOfSpaces = diff + 3
                        var numberOfCurrentSpaces = 0
                        for index in currentLine.indices {
                            guard index > domainClosingBracketIndex else { continue }
                            guard currentLine[index] == " " else { break }

                            numberOfCurrentSpaces += 1
                        }

                        if numberOfCurrentSpaces < requiredNumberOfSpaces {
                            currentLine.insert(
                                contentsOf: space(requiredNumberOfSpaces - numberOfCurrentSpaces),
                                at: currentLine.index(after: domainClosingBracketIndex)
                            )
                        }
                    }
                }

                messageAlignment:
                do {
                    guard
                        let widestMessage = widestMessage,
                        let domainClosingBracketIndex = currentLine.firstIndex(of: "]"),
                        let boundIndex = currentLine.lastIndex(of: "│")
                    else {
                        break messageAlignment
                    }

                    var messageStaringIndex: String.Index?
                    for index in currentLine.indices {
                        guard index > domainClosingBracketIndex else { continue }

                        if currentLine[index] == " " {
                            continue
                        } else {
                            messageStaringIndex = index
                            break
                        }
                    }

                    var messageEndingIndex: String.Index?
                    for index in currentLine.indices.reversed() {
                        guard index < boundIndex else { continue }

                        if currentLine[index] == " " {
                            continue
                        } else {
                            messageEndingIndex = index
                            break
                        }
                    }

                    guard
                        let messageStaringIndex = messageStaringIndex,
                        let messageEndingIndex = messageEndingIndex
                    else {
                        break messageAlignment
                    }

                    let currentMessage = currentLine[messageStaringIndex...messageEndingIndex]
                    let diff = widestMessage.count - currentMessage.count

                    if diff > 0 {
                        let requiredNumberOfSpaces = diff + 1
                        var numberOfCurrentSpaces = 0
                        for index in currentLine.indices {
                            guard index > messageEndingIndex else { continue }
                            guard currentLine[index] == " " else { break }

                            numberOfCurrentSpaces += 1
                        }

                        if numberOfCurrentSpaces < requiredNumberOfSpaces {
                            currentLine.insert(
                                contentsOf: space(requiredNumberOfSpaces - numberOfCurrentSpaces),
                                at: currentLine.index(before: boundIndex)
                            )
                        }
                    }
                }

                newLines.append(currentLine)
            }
        }

        try? writingHandle?.truncate(atOffset: startOffset)

        for newLine in newLines {
            write(newLine)
            write("\n")
        }
    }

    private func writeBoxBottomBound() {
        let footerWidth = footerWidth(from: sessionParams)
        let boxWidth = self.boxWidth

        if footerWidth < boxWidth {
            write("├")
            write(line(footerWidth - 2))
            write("┬")
            write(line(boxWidth - footerWidth - 1))
            write("╯")
            write("\n")
        } else if footerWidth == boxWidth {
            write("├")
            write(line(boxWidth - 2))
            write("┤")
            write("\n")
        } else {
            write("├")
            write(line(boxWidth - 2))
            write("┴")
            write(line(footerWidth - boxWidth - 1))
            write("╮")
            write("\n")
        }
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

        var message = "│" +
            " " +
            logEnrtyTimeDateFormatter.string(from: currentDateResolver()) +
            " " +
            "[" +
            entry.domain.name +
            "]" +
            "   " +
            entry.message +
            " " +
            "│"

        if
            let symbol = entry.level.symbol,
            let file = entry.file,
            let function = entry.function,
            let line = entry.line
        {
            message.append(" \(symbol) \(filename(from: file))::\(function) \(line)")
        }

        write(message)
        write("\n")
        syncAlignment()
    }

    func finish() {
        writeBoxBottomBound()
        writeFooter()
    }
}

extension LogDomain {
    fileprivate static let fileLogger: Self = "fileLogger"
}
