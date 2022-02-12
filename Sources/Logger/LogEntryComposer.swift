protocol LogEntryComposer {
    func compose(_ entry: LogEntry) -> String
}

struct LogEntryComposerImpl: LogEntryComposer {
    func compose(_ entry: LogEntry) -> String {
        entry.message
    }
}
