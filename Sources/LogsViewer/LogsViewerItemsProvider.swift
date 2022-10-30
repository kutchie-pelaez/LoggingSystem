import Core
import CoreUI
import UIKit

private enum SFSymbols: SFSymbolsCollection {
    case ellipsisCircle
    case magnifyingglass
    case squareAndArrowUp
}

struct LogsViewerItemsProvider {
    private let logFilesURLProvider: LogFilesURLProvider

    private let fileManager = FileManager.default

    init(logFilesURLProvider: LogFilesURLProvider) {
        self.logFilesURLProvider = logFilesURLProvider
    }

    func makeDocumentProperties() -> UIDocumentProperties {
        let decryptedFileURL = logFilesURLProvider.decryptedFileURL
        let documentProperties = UIDocumentProperties(url: decryptedFileURL)
        documentProperties.activityViewControllerProvider = {
            UIActivityViewController(
                activityItems: [decryptedFileURL],
                applicationActivities: nil
            )
        }

        return documentProperties
    }

    func makeTitleMenu(shareEncryptedClosure: @escaping ClosureWith<URL>) -> UIMenu? {
        guard fileManager.fileExists(at: logFilesURLProvider.encryptedFileURL) else {
            return nil
        }

        let encryptedFileURL = logFilesURLProvider.encryptedFileURL

        return UIMenu(children: [
            UIAction(title: "Share encrypted", image: SFSymbols.squareAndArrowUp.image, handler: { _ in
                shareEncryptedClosure(encryptedFileURL)
            })
        ])
    }

    func makeRightNavigationItem(closure: @escaping Closure) -> UIBarButtonItem {
        UIBarButtonItem(systemItem: .done, primaryAction: UIAction { _ in
            closure()
        })
    }

    func makeToolbarItems(
        searchClosure: @escaping Closure
    ) -> [UIBarButtonItem] {
        let toolsItem = UIBarButtonItem(image: SFSymbols.ellipsisCircle.image, menu: UIMenu(children: [

        ]))
        let searchItem = UIBarButtonItem(image: SFSymbols.magnifyingglass.image, primaryAction: UIAction { _ in
            searchClosure()
        })

        return [toolsItem, .flexibleSpace(), searchItem]
    }
}
