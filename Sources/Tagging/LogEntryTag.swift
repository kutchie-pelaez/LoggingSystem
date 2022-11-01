import Core

public enum LogEntryTag: String {
    case sessionHeader
    case signpostBegin
    case signpostEnd

    // MARK: RawRepresentable

    public var rawValue: String {
        String(describing: self)
            .camelCaseSplitted()
            .map { $0.uppercased() }
            .joined(separator: "_")
    }
}
