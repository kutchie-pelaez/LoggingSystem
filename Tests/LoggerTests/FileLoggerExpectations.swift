enum FileLoggerExpectations {
    static let logsWithDifferentDomainsAndMessages = """
    +-----------------+
    | Date: January 1 |
    | Session: 1      |
    +-----------------+----------------------------------------------------------+
    | 12:00:00 [LoggerTests.shortDomain]              Really really long message |
    | 12:05:25 [LoggerTests.reallyReallyLongDomain]   Short message              |
    | 13:40:01 [LoggerTests.shortDomain]              Really really long message |
    +----------------------------------------------------------------------------+

    """

    static let logsWithAdditionalParameters = """
    +----------------------------+
    | Date: January 1            |
    | Session: 1                 |
    | Some parameter 1           |
    | Some parameter 2           |
    | Some really long parameter |
    +----------------------------+------------+
    | 12:00:00 [LoggerTests.domain]   Message |
    +-----------------------------------------+

    """

    static let logsWithBoxNarrowerThanFooter = """
    +-------------------------------------------------+
    | Date: January 1                                 |
    | Session: 1                                      |
    | Some really really really really long parameter |
    +-----------------------------------------+-------+
    | 12:00:00 [LoggerTests.domain]   Message |
    +-----------------------------------------+

    """

    static let logsWithBoxEqualToFooter = """
    +-----------------------------------------+
    | Date: January 1                         |
    | Session: 1                              |
    | Some parameter 123456789012345678901234 |
    +-----------------------------------------+
    | 12:00:00 [LoggerTests.domain]   Message |
    +-----------------------------------------+

    """

    static let logsWithWarningsAndErrors = """
    +-----------------+
    | Date: January 1 |
    | Session: 1      |
    +-----------------+------------------------+
    | 12:00:00 [LoggerTests.log]       Message |
    | 12:00:00 [LoggerTests.warning]   Warning | 🟡 FileLoggerTests::test5_withWarningsAndErrors() 161
    | 12:00:00 [LoggerTests.error]     Error   | 🔴 FileLoggerTests::test5_withWarningsAndErrors() 163
    +------------------------------------------+

    """

    static let logsWithManySessions = """
    +-----------------+
    | Date: January 1 |
    | Session: 1      |
    +-----------------+-----------------------+
    | 12:00:00 [LoggerTests.domain]   Message |
    +-----------------------------------------+

    +-----------------+
    | Date: January 4 |
    | Session: 2      |
    +-----------------+-----------------------+
    | 12:00:00 [LoggerTests.domain]   Message |
    +-----------------------------------------+

    +------------------+
    | Date: January 10 |
    | Session: 3       |
    +------------------+----------------------+
    | 12:00:00 [LoggerTests.domain]   Message |
    +-----------------------------------------+

    """
}
