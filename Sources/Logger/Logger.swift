public protocol Logger {
    func log(_ entry: LogEntry)
}

extension Logger {
    public func log(_ message: String, domain: LogDomain) {
        let entry = LogEntry(
            message: message,
            domain: domain
        )

        log(entry)
    }
}
