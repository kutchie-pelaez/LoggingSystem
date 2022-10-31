import Darwin

enum LogDateFormatter {
    static func currentTimestamp() -> String {
        var timeval = timeval(tv_sec: 0, tv_usec: 0)
        gettimeofday(&timeval, nil)

        var buffer = [Int8](repeating: 0, count: 255)
        let localtime = localtime(&timeval.tv_sec)!
        let ms = String(format: "%03d", timeval.tv_usec / 1000)
        strftime(&buffer, buffer.count, "%d-%m-%Y %H:%M:%S.\(ms)%z", localtime)

        return buffer.withUnsafeBufferPointer {
            $0.withMemoryRebound(to: CChar.self) {
                String(cString: $0.baseAddress!)
            }
        }
    }
}
