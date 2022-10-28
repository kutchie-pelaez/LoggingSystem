public struct LogEntryDecryptor {
    private let decryptionKey: String

    public init(decryptionKey: String) {
        self.decryptionKey = decryptionKey
    }

    public func decrypt(_ log: String) -> String {
        log
    }
}
