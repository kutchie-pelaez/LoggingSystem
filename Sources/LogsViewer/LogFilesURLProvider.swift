import Foundation

struct LogFilesURLProvider {
    var logsDirectoryURL: URL { fileManager.temporaryDirectory.appending(path: "logs") }

    var encryptedDirectoryURL: URL { logsDirectoryURL.appending(path: "encrypted") }

    var decryptedDirectoryURL: URL { logsDirectoryURL.appending(path: "decrypted") }

    var encryptedFileURL: URL { encryptedDirectoryURL.appending(path: name) }

    var decryptedFileURL: URL { decryptedDirectoryURL.appending(path: name) }

    private let name: String

    private let fileManager = FileManager.default

    init(name: String) {
        self.name = name
    }
}
