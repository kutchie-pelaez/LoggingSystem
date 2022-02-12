public protocol Logger {
    func log(_ entry: LogEntry)
}

extension Logger {
    public func log(_ message: String, domain: LogDomain) {
        let entry = LogEntry(
            message: message,
            level: .log,
            domain: domain
        )

        log(entry)
    }

    public func warning(_ message: String, domain: LogDomain) {
        let entry = LogEntry(
            message: message,
            level: .warning,
            domain: domain
        )

        log(entry)
    }

    public func error(_ message: String, domain: LogDomain) {
        let entry = LogEntry(
            message: message,
            level: .error,
            domain: domain
        )

        log(entry)
    }
}
