import Core
import DeviceKit
import Foundation
import Logs

public protocol LogsComposerProvider {
    var logsURL: URL { get }
    var userInfo: Logs.UserInfo { get }
    var additionalUserInfo: [String: String] { get }
}

extension LogsComposerProvider {
    public var logsURL: URL {
        FileManager.default
            .documents
            .appendingPathComponent("logs")
    }

    public var userInfo: Logs.UserInfo {
        Logs.UserInfo(
            appVersion: .current,
            systemVersion: Device.current.systemVersion,
            device: Device.current.description
        )
    }

    public var additionalUserInfo: [String: String] {
        [:]
    }
}
