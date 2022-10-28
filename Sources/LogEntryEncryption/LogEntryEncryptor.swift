public struct LogEntryEncryptor {
    private let encryptionKey: String

    public init(encryptionKey: String) {
        self.encryptionKey = encryptionKey
    }

    public func encrypt(_ log: String) -> String {
        log
    }
}
