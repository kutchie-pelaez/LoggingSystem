enum FileLoggerExpectations {
    static let logsWithDifferentDomainsAndMessages = """
    +-----------------+
    | Date: January 1 |
    | Session: 1      |
    +-----------------+----------------------------------------------+
    | 12:00:00 [shortDomain]              Really really long message |
    | 12:05:25 [reallyReallyLongDomain]   Short message              |
    | 13:40:01 [shortDomain]              Really really long message |
    +----------------------------------------------------------------+

    """

    static let logsWithAdditionalParameters = """
    +----------------------------+
    | Date: January 1            |
    | Session: 1                 |
    | Some parameter 1           |
    | Some parameter 2           |
    | Some really long parameter |
    +----------------------------++
    | 12:00:00 [domain]   Message |
    +-----------------------------+

    """

    static let logsWithBoxNarrowerThanFooter = """
    +-----------------------------------+
    | Date: January 1                   |
    | Session: 1                        |
    | Some really really long parameter |
    +-----------------------------+-----+
    | 12:00:00 [domain]   Message |
    +-----------------------------+

    """

    static let logsWithBoxEqualToFooter = """
    +-----------------------------+
    | Date: January 1             |
    | Session: 1                  |
    | Some parameter 123456789012 |
    +-----------------------------+
    | 12:00:00 [domain]   Message |
    +-----------------------------+

    """

    static let logsWithWarningsAndErrors = """
    +-----------------+
    | Date: January 1 |
    | Session: 1      |
    +-----------------+------------+
    | 12:00:00 [log]       Message |
    | 12:00:00 [warning]   Warning | 🟡 FileLoggerTests::test5_withWarningsAndErrors() 158
    | 12:00:00 [error]     Error   | 🔴 FileLoggerTests::test5_withWarningsAndErrors() 160
    +------------------------------+

    """

    static let logsWithManySessions = """
    +-----------------+
    | Date: January 1 |
    | Session: 1      |
    +-----------------+-----------+
    | 12:00:00 [domain]   Message |
    +-----------------------------+

    +-----------------+
    | Date: January 4 |
    | Session: 2      |
    +-----------------+-----------+
    | 12:00:00 [domain]   Message |
    +-----------------------------+

    +------------------+
    | Date: January 10 |
    | Session: 3       |
    +------------------+----------+
    | 12:00:00 [domain]   Message |
    +-----------------------------+

    """
}
