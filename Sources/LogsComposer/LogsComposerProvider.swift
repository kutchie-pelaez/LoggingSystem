import Foundation
import Logs

public protocol LogsComposerProvider {
    var logsURL: URL { get }
    var userInfo: Logs.UserInfo { get }
    var additionalUserInfo: [String: String] { get }
}
