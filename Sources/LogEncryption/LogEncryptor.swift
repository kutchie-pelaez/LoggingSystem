public struct LogEncryptor {
    private let secret: String

    public init(secret: String) {
        self.secret = secret
    }

    public func encrypt(_ log: String) -> String {
        log
    }
}
