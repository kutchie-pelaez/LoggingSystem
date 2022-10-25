import Darwin

struct LogDateFormatter {
    private let format: String

    init(format: String = "%d-%m-%Y %H:%M:%S%z") {
        self.format = format
    }

    func currentTimestamp() -> String {
        var buffer = [Int8](repeating: 0, count: 255)
        var timestamp = time(nil)
        let localTime = localtime(&timestamp)
        strftime(&buffer, buffer.count, format, localTime)

        return buffer.withUnsafeBufferPointer {
            $0.withMemoryRebound(to: CChar.self) {
                String(cString: $0.baseAddress!)
            }
        }
    }
}
