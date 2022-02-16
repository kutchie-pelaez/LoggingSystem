import Core
import Foundation
import SessionManager

protocol FileLoggerWriter {
    func writeNewLine()
    func writeHeader()
    func writeMessage(_ message: String)
    func updateWidestDomainIfNeeded(_ newDomain: String)
    func updateWidestMessageIfNeeded(_ newMessage: String)
}

final class FileLoggerWriterImpl: FileLoggerWriter {
    init(
        logsURL: URL,
        sessionParams: [String]
    ) {
        self.logsURL =  logsURL
        self.sessionParams =  sessionParams
    }

    deinit {
        try? readingHandle?.close()
        try? writingHandle?.close()
    }

    private let logsURL: URL
    private let sessionParams: [String]

    private lazy var readingHandle: FileHandle? = {
        safeUndefinedIfNil(
            try? FileHandle(forReadingFrom: logsURL),
            nil
        )
    }()

    private lazy var writingHandle: FileHandle? = {
        safeUndefinedIfNil(
            try? FileHandle(forWritingTo: logsURL),
            nil
        )
    }()

    private var startingOffset: UInt64?

    private var widestDomain: String?
    private var widestMessage: String?

    private let queue = DispatchQueue(label: "com.kulikovia.Logging")

    // MARK: -

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

    private func space(_ count: Int) -> String {
        Array(repeating: " ", count: count).joined()
    }

    private func line(_ count: Int) -> String {
        Array(repeating: "-", count: count).joined()
    }

    private var headerWidth: Int {
        sessionParams.map { 2 + $0.count + 2}.max()!
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

    private var headerTopSide: String {
        "+" + line(headerWidth - 2) + "+"
    }

    private var boxTopSide: String {
        var result = ""

        if headerWidth < boxWidth {
            result.append("+")
            result.append(line(headerWidth - 2))
            result.append("+")
            result.append(line(boxWidth - headerWidth - 1))
            result.append("+")
        } else if headerWidth == boxWidth {
            result.append("+")
            result.append(line(boxWidth - 2))
            result.append("+")
        } else {
            result.append("+")
            result.append(line(boxWidth - 2))
            result.append("+")
            result.append(line(headerWidth - boxWidth - 1))
            result.append("+")
        }

        return result
    }

    private var boxBottomSide: String {
        "+" + line(boxWidth - 2) + "+"
    }

    private func syncMessagesAlignment() {
        guard let startingOffset = startingOffset else {
            return
        }

        try? readingHandle?.seek(toOffset: startingOffset)

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

        for (index, var currentLine) in currentLines.enumerated() {
            if index == 0 {
                newLines.append(boxTopSide)
            } else if currentLine.starts(with: "+") {
                continue
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
                        let boundIndex = currentLine.lastIndex(of: "|")
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

        try? writingHandle?.truncate(atOffset: startingOffset)

        newLines.append(boxBottomSide)
        for newLine in newLines {
            write(newLine)
            write("\n")
        }
    }

    // MARK: - FileLoggerWriter

    func writeNewLine() {
        write("\n")
    }

    func writeHeader() {
        write(headerTopSide)
        writeNewLine()

        for sessionParam in sessionParams {
            let rightSpaces = space(headerWidth - 2 - sessionParam.count - 1)
            let line = "| \(sessionParam)\(rightSpaces)|"

            write(line)
            writeNewLine()
        }

        startingOffset = try? writingHandle?.offset()
        write(boxTopSide)
        writeNewLine()
    }

    func writeMessage(_ message: String) {
        queue.sync {
            write(message)
            writeNewLine()
            syncMessagesAlignment()
        }
    }

    func updateWidestDomainIfNeeded(_ newDomain: String) {
        guard widestDomain.isNil || newDomain.count > widestDomain!.count else { return }

        widestDomain = newDomain
    }

    func updateWidestMessageIfNeeded(_ newMessage: String) {
        guard widestMessage.isNil || newMessage.count > widestMessage!.count else { return }

        widestMessage = newMessage
    }
}
