import Core

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
        public init(
            appVersion: Version,
            systemVersion: String,
            device: String
        ) {
            self.appVersion = appVersion
            self.systemVersion = systemVersion
            self.device = device
        }

        let appVersion: Version
        let systemVersion: String
        let device: String
    }

    public struct Entry: Encodable {

    }
}
