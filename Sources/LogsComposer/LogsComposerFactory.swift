public struct LogsComposerFactory {
    public init() { }

    public func produce(provider: LogsComposerProvider) -> LogsComposer {
        LogsComposerImpl(provider: provider)
    }
}
