public struct LogEntryDecryptor {
    private let secret: String

    public init(secret: String) {
        self.secret = secret
    }

    public func decrypt(_ log: String) -> String {
        log
    }
}
