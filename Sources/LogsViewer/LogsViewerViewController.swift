import AlertBuilder
import CoreUI
import UIKit

private enum ErrorCTA {
    case askForDecryptionKey
}

final class LogsViewerViewController<AB: AlertBuilder>: ViewController {
    private let name: String
    private let repository: LogEntriesRepository
    private let itemsProvider: LogsViewerItemsProvider
    private let alertBuilder: AB

    private var query: LogsQuery? {
        didSet {
            perform(query: query)
        }
    }

    private var state: Result<[LogEntry], LogEntriesRepositoryError> = .failure(.noEntries) {
        didSet {
            switch state {
            case .success(let entries):
                refresh(with: entries)

            case .failure(let error):
                handle(error: error)
            }
        }
    }

    init(
        name: String,
        repository: LogEntriesRepository,
        itemsProvider: LogsViewerItemsProvider,
        alertBuilder: AB
    ) {
        self.name = name
        self.repository = repository
        self.itemsProvider = itemsProvider
        self.alertBuilder = alertBuilder
        super.init()
    }

    override func viewDidLoad() {
        configureNavigationBar()
        configureViews()
        handle(error: .noEntries)
        perform(query: nil)
    }

    private func configureNavigationBar() {
        navigationItem.title = name
        navigationItem.documentProperties = itemsProvider.makeDocumentProperties()
        navigationItem.titleMenuProvider = { [weak self] _ in
            guard let self else { return nil }

            return self.itemsProvider.makeTitleMenu(shareEncryptedClosure: { encryptedFileURL in
                let activityViewController = UIActivityViewController(
                    activityItems: [encryptedFileURL],
                    applicationActivities: nil
                )
                self.present(activityViewController, animated: true)
            })
        }
        navigationItem.leftBarButtonItem = itemsProvider.makeLeftNavigationItem()
        navigationItem.rightBarButtonItem = itemsProvider.makeRightNavigationItem { [weak self] in
            self?.dismiss(animated: true)
        }
        navigationItem.searchController = UISearchController()
        navigationItem.preferredSearchBarPlacement = .stacked
    }

    private func configureViews() {
        view.backgroundColor = .systemBackground
    }

    private func perform(query: LogsQuery?) {
        do {
            let entries = try repository.entries(for: query)
            state = .success(entries)
        } catch let error as LogEntriesRepositoryError {
            state = .failure(error)
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    private func refresh(with entries: [LogEntry]) {

    }

    private func handle(error: LogEntriesRepositoryError) {
        let errorDescryption: String
        let errorCTA: ErrorCTA?

        switch error {
        case .noEntries:
            errorDescryption = "Logs file has no entries."
            errorCTA = nil

        case .invalidDecryptionKey(let description):
            errorDescryption = ["Invalid decryption key:", description].joined(separator: "\n")
            errorCTA = .askForDecryptionKey

        case .noHeaderForEntry(let rawEntry):
            errorDescryption = ["No header for entry:", rawEntry].joined(separator: "\n")
            errorCTA = nil

        case .invalidHeader(let rawHeader):
            errorDescryption = ["Invalid header:", rawHeader].joined(separator: "\n")
            errorCTA = nil

        case .invalidEntry(let rawEntry):
            errorDescryption = ["Invalid entry:", rawEntry].joined(separator: "\n")
            errorCTA = nil

        case .invalidMetadata(let description):
            errorDescryption = ["Invalid metadata:", description].joined(separator: "\n")
            errorCTA = nil
        }

        if let errorCTA {
            switch errorCTA {
            case .askForDecryptionKey:
                break
            }
        } else {

        }
    }

    private func askForDecryptionKey() {
        let alertController = alertBuilder.build(using: Alert(
            message: "Enter decryption key",
            actions: [.cancel, .done { [weak self] in
                self?.repository.setDecryptionKey("")
                self?.perform(query: self?.query)
            }]
        ))
        present(alertController, animated: true)
    }
}
