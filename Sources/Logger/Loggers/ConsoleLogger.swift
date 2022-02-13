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

    func log(_ entry: LogEntry, to target: LogTarget) {
        guard target.contains(.console) else { return }

        let message = composer.compose(entry)
        print(message)
    }
}
