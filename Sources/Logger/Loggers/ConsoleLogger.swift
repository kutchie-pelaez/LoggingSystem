import Core
import os

struct ConsoleLogger: Logger {
    init?(
        environment: Environment,
        composer: LogEntryComposer
    ) {
        guard environment.isDev else { return nil }

        self.composer = composer
    }

    private let composer: LogEntryComposer

    // MARK: - Logger

    func log(_ entry: LogEntry) {
        let message = composer.compose(entry)
        print(message)
    }
}
