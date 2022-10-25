public struct LogDecoder {
    private let secret: String

    public init(secret: String) {
        self.secret = secret
    }

    func decode(_ log: String) -> String {
        fatalError()
    }
}
