import Core

private let signpostLabelTag = "SIGNPOST"
private let separator = ":::"

public enum LoggerType: CustomStringConvertible {
    case `default`(label: String)
    case signpost(label: String, group: String)

    public var label: String {
        switch self {
        case .default(let label):
            return label

        case .signpost(let label, _):
            return label
        }
    }

    public init(from label: String) {
        let signpostSplits = label.split(separator: separator)
        if
            signpostSplits.count > 2 &&
            signpostSplits[safe: 0].map(String.init) == signpostLabelTag,
            let group = signpostSplits[safe: 1].map(String.init),
            let label = signpostSplits[safe: 2].map(String.init)
        {
            self = .signpost(label: label, group: group)
        } else {
            self = .default(label: label)
        }
    }

    // MARK: CustomStringConvertible

    public var description: String {
        switch self {
        case .default(let label):
            return label

        case .signpost(let label, let group):
            return [signpostLabelTag, group, label].joined(separator: separator)
        }
    }
}
