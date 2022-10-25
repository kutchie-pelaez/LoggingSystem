import LogsExtractor

public enum LogsExtractorFactory {
    public static func produce(secret: String) -> some LogsExtractor {
        LogsExtractorImpl(secret: secret)
    }
}
