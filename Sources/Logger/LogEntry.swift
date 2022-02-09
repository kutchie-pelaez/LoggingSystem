public struct LogEntry {
    public init(
        message: String,
        domain: LogDomain
    ) {
        self.message = message
        self.domain = domain
    }

    let message: String
    let domain: LogDomain
}
