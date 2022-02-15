public struct LogsExtractorFactory {
    public init() { }

    public func produce(provider: LogsExtractorProvider) -> LogsExtractor {
        LogsExtractorImpl(provider: provider)
    }
}
