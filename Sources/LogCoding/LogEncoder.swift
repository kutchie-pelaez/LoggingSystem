public struct LogEncoder {
    private let secret: String

    public init(secret: String) {
        self.secret = secret
    }

    func encode(_ log: String) -> String {
        fatalError()
    }
}
