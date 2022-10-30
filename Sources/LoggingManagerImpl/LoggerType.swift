enum LoggerType {
    case regular
    case signpost

    init(from label: String) {
        let signpostSplits = label.split(separator: "::")
        if signpostSplits.count > 2 && signpostSplits.first == "signpost" {
            self = .signpost
        } else {
            self = .regular
        }
    }
}
