public struct LogEntryDecryptor {
    private let decryptionKey: String

    public init(decryptionKey: String) {
        self.decryptionKey = decryptionKey
    }

    // TODO: - Implement decryption

    public func decrypt(_ log: String) throws -> String {
        log
    }
}
