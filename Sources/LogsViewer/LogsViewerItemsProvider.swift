import Core
import CoreUI
import LinkPresentation
import Logging
import UIKit

private enum SFSymbols: SFSymbolsCollection {
    case ellipsisCircle
    case squareAndArrowUp
}

struct LogEntriesGroup<T> {
    let term: T
    let entriesCount: Int
}

protocol LogsViewerItemsProviderDataSource: AnyObject {
    func avalilableLevelsDidReqest() -> [LogEntriesGroup<Logger.Level>]
    func avalilableLabelsDidReqest() -> [LogEntriesGroup<String>]
    func avalilableSourcesDidReqest() -> [LogEntriesGroup<String>]
}

final class LogsViewerItemsProvider {
    weak var dataSource: LogsViewerItemsProviderDataSource?

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

    func makeLeftNavigationItem() -> UIBarButtonItem {
        UIBarButtonItem(image: SFSymbols.ellipsisCircle.image, menu: UIMenu(children: [
            makeLevelFilterItem(),
            makeLabelFilterItem(),
            makeSourceFilterItem()
        ].unwrapped()))
    }

    func makeRightNavigationItem(closure: @escaping Closure) -> UIBarButtonItem {
        UIBarButtonItem(systemItem: .close, primaryAction: UIAction { _ in
            closure()
        })
    }

    private func makeLevelFilterItem() -> UIMenuElement? {
        makeFilterItem(title: "Levels", groupsResolver: dataSource?.avalilableLevelsDidReqest)
    }

    private func makeLabelFilterItem() -> UIMenuElement? {
        makeFilterItem(title: "Labels", groupsResolver: dataSource?.avalilableLabelsDidReqest)
    }

    private func makeSourceFilterItem() -> UIMenuElement? {
        makeFilterItem(title: "Sources", groupsResolver: dataSource?.avalilableSourcesDidReqest)
    }

    private func makeFilterItem<T>(
        title: String,
        groupsResolver: (() -> [LogEntriesGroup<T>])?
    ) -> UIMenuElement? {
        guard let groups = groupsResolver?(), groups.count > 1 else { return nil }

        return UIMenu(title: title, children: [
            UIAction(title: "All", state: .on, handler: { _ in

            }),
            UIMenu(options: .displayInline, children: groups.map { group in
                let title = "\(group.term)"
                let subtitle = "\(group.entriesCount) entries"

                return UIAction(title: title, subtitle: subtitle, state: .off, handler: { _ in
                    print(group.term)
                })
            })
        ])
    }
}
