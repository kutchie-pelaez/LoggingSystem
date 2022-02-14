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

    private let subject: Logger = {
        LoggerFactory().produce(
            environment: .prod,
            sessionManager: SessionManagerMock(),
            provider: LoggerProviderMock()
        )
    }()

    func test1_() {

    }
}

private struct SessionManagerMock: SessionManager {
    var underlyingSession = 0

    var session: Int { underlyingSession }
    func start() { }
}

private struct LoggerProviderMock: LoggerProvider {
    var underlyingGessionAdditionalParams = [String]()

    var logsURL: URL { testsLogsURL }
    var sessionAdditionalParams: [String] { underlyingGessionAdditionalParams }
}
