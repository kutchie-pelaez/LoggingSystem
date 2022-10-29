import CoreUI
import UIKit

final class LogsViewerViewController: ViewController {
    private let repository: LogEntriesRepository

    init(repository: LogEntriesRepository) {
        self.repository = repository
        super.init()
    }

    override func viewDidLoad() {
        do {
            let entries = try repository.entries(for: nil)
            print("=================")
            print(entries)
        } catch {
            print("=================")
            print(error)
        }
    }
}
