public struct Logs: Encodable {
    public init(
        userInfo: UserInfo,
        entries: [Entry]
    ) {
        self.userInfo = userInfo
        self.entries = entries
    }

    let userInfo: UserInfo
    let entries: [Entry]

    public struct UserInfo: Encodable {

    }

    public struct Entry: Encodable {

    }
}
