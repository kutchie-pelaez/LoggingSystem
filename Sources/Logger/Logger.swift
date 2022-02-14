import Core

public protocol Logger {
    func log(_ entry: LogEntry, to target: LogTarget)
}

extension Logger {
    public func log(_ message: String, domain: LogDomain) {
        let entry = LogEntry(
            message: message,
            level: .log,
            domain: domain
        )

        log(
            entry,
            to: .all
        )
    }

    public func warning(
        _ message: String,
        domain: LogDomain,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let entry = LogEntry(
            message: message,
            level: .warning,
            domain: domain,
            file: file,
            function: function,
            line: line
        )

        log(
            entry,
            to: .all
        )
    }

    public func error(
        _ message: String,
        domain: LogDomain,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let entry = LogEntry(
            message: message,
            level: .error,
            domain: domain,
            file: file,
            function: function,
            line: line
        )

        log(
            entry,
            to: .all
        )
    }
}
