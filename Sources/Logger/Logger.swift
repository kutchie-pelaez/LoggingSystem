public protocol Logger {
    func log(_ entry: LogEntry)
    func error(_ entry: LogEntry)
}

extension Logger {
    public func log(_ message: String, domain: LogDomain) {
        let entry = LogEntry(
            message: message,
            domain: domain
        )

        log(entry)
    }

    public func error(_ message: String, domain: LogDomain) {
        let entry = LogEntry(
            message: message,
            domain: domain
        )

        error(entry)
    }
}
