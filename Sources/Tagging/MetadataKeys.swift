import Core

public enum MetadataKeys: String {
    case file
    case function
    case label
    case level
    case line
    case sessionNumber
    case signpostGroup
    case signpostID
    case source
    case thread
    case timestamp
    case version

    // MARK: RawRepresentable

    public var rawValue: String {
        String(describing: self)
            .camelCaseSplitted()
            .map { $0.uppercased() }
            .joined(separator: "_")
    }
}
