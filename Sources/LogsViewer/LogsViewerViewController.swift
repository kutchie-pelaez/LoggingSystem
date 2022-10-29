import CoreUI
import UIKit

final class LogsViewerViewController: ViewController {
    private let repository: LogEntriesRepository

    init(repository: LogEntriesRepository) {
        self.repository = repository
        super.init()
    }

    override func viewDidLoad() {

    }
}
