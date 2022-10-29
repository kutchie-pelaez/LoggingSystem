public struct LogEntryEncryptor {
    private let encryptionKey: String

    public init(encryptionKey: String) {
        self.encryptionKey = encryptionKey
    }

    // TODO: - Implement encryption

    public func encrypt(_ log: String) -> String {
        log
    }
}
