import Core
import CoreUI
import LinkPresentation
import Logging
import UIKit

private enum SFSymbols: SFSymbolsCollection {
    case calendar
    case ellipsisCircle
    case hammerFill
    case personBadgeClockFill
    case squareAndArrowUp
}

enum LogEntrySortOption: String, CaseIterable {
    case dateAscending = "Oldest to newest"
    case dateDescending = "Newest to oldest"
    case alphabeticallyAscending = "A to Z"
    case alphabeticallyDescending = "Z to A"
}

enum LogEntriesGroupSortOption: String, CaseIterable {
    case alphabeticallyAscending = "A to Z"
    case alphabeticallyDescending = "Z to A"
    case entriesCountAscending = "Most entries"
    case entriesCountDescending = "Least entries"
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
    var call: Closure?
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
            UIMenu(title: "Sorting", options: .displayInline, children: [
                makeEntriesSortItem(),
                makeGroupsSortItem()
            ]),
            UIMenu(title: "Filtering", options: .displayInline, children: [
                makeLevelFilterItem(),
                makeLabelFilterItem(),
                makeSourceFilterItem()
            ].unwrapped()),
            UIMenu(options: .displayInline, children: [
                UIAction(title: "Date", image: SFSymbols.calendar.image, handler: { _ in

                }),
                UIAction(title: "Version", image: SFSymbols.hammerFill.image, handler: { _ in

                }),
                UIAction(title: "Session", image: SFSymbols.personBadgeClockFill.image, handler: { _ in

                })
            ])
        ]))
    }

    func makeRightNavigationItem(closure: @escaping Closure) -> UIBarButtonItem {
        UIBarButtonItem(systemItem: .close, primaryAction: UIAction { _ in
            closure()
        })
    }

    private func makeLevelFilterItem() -> UIMenuElement? {
        makeFilterItem(title: "Level", groupsResolver: dataSource?.avalilableLevelsDidReqest)
    }

    private func makeLabelFilterItem() -> UIMenuElement? {
        makeFilterItem(title: "Label", groupsResolver: dataSource?.avalilableLabelsDidReqest)
    }

    private func makeSourceFilterItem() -> UIMenuElement? {
        makeFilterItem(title: "Source", groupsResolver: dataSource?.avalilableSourcesDidReqest)
    }

    private func makeEntriesSortItem() -> UIMenuElement {
        makeSortItem(
            title: "Entries sorting",
            optionsType: LogEntrySortOption.self,
            selectedOption: .dateAscending
        )
    }

    private func makeGroupsSortItem() -> UIMenuElement {
        makeSortItem(
            title: "Groups sorting",
            optionsType: LogEntriesGroupSortOption.self,
            selectedOption: .entriesCountAscending
        )
    }

    private func makeFilterItem<T>(
        title: String,
        groupsResolver: (() -> [LogEntriesGroup<T>])?
    ) -> UIMenuElement? {
        guard let groups = groupsResolver?(), groups.count > 0 else { return nil }

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

    private func makeSortItem<O: CaseIterable & RawRepresentable>(
        title: String,
        optionsType: O.Type,
        selectedOption: O
    ) -> UIMenuElement where O.RawValue == String {
        UIMenu(title: title, children: O.allCases.map { option in
            let state: UIAction.State = option == selectedOption ? .on : .off

            return UIAction(title: option.rawValue, state: state, handler: { _ in
                print(option.rawValue)
            })
        })
    }
}
