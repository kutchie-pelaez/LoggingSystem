import Foundation

struct LogFilesURLProvider {
    var encryptedFileURL: URL {
        encryptedDirectoryURL.appending(path: name)
    }

    var decryptedFileURL: URL {
        decryptedDirectoryURL.appending(path: name)
    }

    private let name: String

    private let fileManager = FileManager.default
    private var logsDirectoryURL: URL {
        fileManager.temporaryDirectory.appending(path: "logs")
    }
    private var encryptedDirectoryURL: URL {
        logsDirectoryURL.appending(path: "encrypted")
    }
    private var decryptedDirectoryURL: URL {
        logsDirectoryURL.appending(path: "decrypted")
    }

    init(name: String) {
        self.name = name
    }
}
