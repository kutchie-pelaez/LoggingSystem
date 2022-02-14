@testable import Logger
import Core
import SessionManager
import XCTest

private let loggerTestsURL = URL(fileURLWithPath: #file)
private let fixturesURL = loggerTestsURL
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .appendingPathComponent("Fixtures")
private let testsLogsURL = fixturesURL
    .appendingPathComponent("logs")

final class LoggerTests: XCTestCase {
    override class func setUp() {
        cleanup()
    }

    override class func tearDown() {
        cleanup()
    }

    private static func cleanup() {
        try? "".write(
            to: testsLogsURL,
            atomically: true,
            encoding: .utf8
        )
    }

    private let sessionManagerMock = SessionManagerMock()
    private let loggerProviderMock = LoggerProviderMock()

    private func makeSubject() -> Logger {
        FileLogger(
            provider: loggerProviderMock,
            sessionManager: sessionManagerMock,
            consoleLogger: ConsoleLogger(
                environment: .dev
            ),
            currentDateResolver: currentDate
        )
    }

    private var _currentDate: Date = .now
    private func currentDate() -> Date { _currentDate }
    private func testDate(shiftedBy timeInterval: TimeInterval) -> Date {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "en_US")
        let referenceDateComponents = DateComponents(
            calendar: calendar,
            timeZone: TimeZone(secondsFromGMT: 0),
            year: 2022,
            month: 1,
            day: 1,
            hour: 12,
            minute: 0,
            second: 0
        )
        let referenceDate = calendar.date(from: referenceDateComponents)!

        return referenceDate.addingTimeInterval(timeInterval)
    }

    private var logs: String {
        String(
            data: try! Data(contentsOf: testsLogsURL),
            encoding: .utf8
        )!
    }

    private var subject: Logger!

    func test1_withDifferentDomainsAndMessages() {
        _currentDate = testDate(shiftedBy: 0)
        subject = makeSubject()

        _currentDate = testDate(shiftedBy: 0)
        subject.log("Really really long message", domain: .shortDomain)

        _currentDate = testDate(shiftedBy: .minutes(5) + .seconds(25))
        subject.log("Short message", domain: .reallyReallyLongDomain)

        _currentDate = testDate(shiftedBy: .hour + .minutes(40) + .second)
        subject.log("Really really long message", domain: .shortDomain)

        _currentDate = testDate(shiftedBy: .hours(2) + .minutes(45) + .second)
        sessionManagerMock.underlyingSession = 1
        subject.finish()

        XCTAssertEqual(
            logs,
            FileLoggerExpectations.logsWithDifferentDomainsAndMessages
        )

        Self.cleanup()
    }

    func test2_withAdditionalParameters() {
        _currentDate = testDate(shiftedBy: 0)
        subject = makeSubject()

        subject.log("Message", domain: .domain)
        sessionManagerMock.underlyingSession = 1
        loggerProviderMock.underlyingSessionAdditionalParams = [
            "Some parameter 1",
            "Some parameter 2",
            "Some really long parameter"
        ]
        subject.finish()

        XCTAssertEqual(
            logs,
            FileLoggerExpectations.logsWithAdditionalParameters
        )

        Self.cleanup()
    }

    func test3_withBoxNarrowerThanFooter() {
        _currentDate = testDate(shiftedBy: 0)
        subject = makeSubject()

        subject.log("Message", domain: .domain)
        sessionManagerMock.underlyingSession = 1
        loggerProviderMock.underlyingSessionAdditionalParams = [
            "Some really really long parameter"
        ]
        subject.finish()

        XCTAssertEqual(
            logs,
            FileLoggerExpectations.logsWithBoxNarrowerThanFooter
        )

        Self.cleanup()
    }

    func test4_withWarningsAndErrors() {
        _currentDate = testDate(shiftedBy: 0)
        subject = makeSubject()

        subject.log("Message", domain: .log)

        subject.warning("Warning", domain: .warning)

        subject.error("Error", domain: .error)

        sessionManagerMock.underlyingSession = 1
        subject.finish()

        XCTAssertEqual(
            logs,
            FileLoggerExpectations.logsWithWarningsAndErrors
        )

        Self.cleanup()
    }

    func test5_withManySessions() {
        _currentDate = testDate(shiftedBy: 0)
        subject = makeSubject()
        subject.log("Message", domain: .domain)
        _currentDate = testDate(shiftedBy: .hour)
        sessionManagerMock.underlyingSession = 1
        subject.finish()

        _currentDate = testDate(shiftedBy: .days(3))
        subject = makeSubject()
        subject.log("Message", domain: .domain)
        _currentDate = testDate(shiftedBy: .days(3) + .hours(3))
        sessionManagerMock.underlyingSession = 2
        subject.finish()

        _currentDate = testDate(shiftedBy: .days(9))
        subject = makeSubject()
        subject.log("Message", domain: .domain)
        _currentDate = testDate(shiftedBy: .days(9) + .hours(5))
        sessionManagerMock.underlyingSession = 3
        subject.finish()

        XCTAssertEqual(
            logs,
            FileLoggerExpectations.logsWithManySessions
        )

        Self.cleanup()
    }
}

extension LogDomain {
    fileprivate static let shortDomain: Self = "shortDomain"
    fileprivate static let reallyReallyLongDomain: Self = "reallyReallyLongDomain"
    fileprivate static let log: Self = "log"
    fileprivate static let warning: Self = "warning"
    fileprivate static let error: Self = "error"
    fileprivate static let domain: Self = "domain"
}

private final class SessionManagerMock: SessionManager {
    var underlyingSession = 0

    var session: Int { underlyingSession }
    func start() { }
}

private final class LoggerProviderMock: LoggerProvider {
    var underlyingSessionAdditionalParams = [String]()

    var logsURL: URL { testsLogsURL }
    var sessionAdditionalParams: [String] { underlyingSessionAdditionalParams }
}
