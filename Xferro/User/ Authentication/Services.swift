import Cocoa
import Siesta
import os

let serviceLogger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "services")

protocol AccountService: AnyObject {
    init?(account: Account, password: String)
    func accountUpdated(oldAccount: Account, newAccount: Account)
}

class IdentifiableService: Service, Identifiable {
    let id = UUID()
}

/// Manages and provides access to all service API instances.
final class Services {
    /// Status of server operations such as authentication.
    enum Status {
        case unknown
        case notStarted
        case inProgress
        case done
        case failed(Error?)
    }

    typealias RepositoryService = IdentifiableService & AccountService

    static let shared = Services(tokenStorage: KeychainStorage.shared)

    let tokenStorage: any TokenStorage

    private var bitbucketServices: [String: BitbucketServerAPI] = [:]

    private var services: [AccountType: [String: BasicAuthService]] = [:]
    var allServices: [any RepositoryService] {
        services.values.flatMap { $0.values }
    }

    var serviceMakers: [AccountType: (Account) -> BasicAuthService?] = [:]

    init(tokenStorage: any TokenStorage) {
        self.tokenStorage = tokenStorage

        let bbsMaker: (Account) -> BitbucketServerAPI? = createService(for:)

        serviceMakers[.bitbucketServer] = bbsMaker

        NotificationCenter.default.addObserver(
            forName: .authenticationStatusChanged,
            object: nil,
            queue: .main
        ) { notification in
            guard let service = notification.object as? BasicAuthService
            else { return }

            if case .failed(let error) = service.authenticationStatus {
                fatalError(.unhandledError(error?.localizedDescription ?? "Unknown error"))
            }
        }
    }

    func pullRequestService(forID id: UUID) -> (any PullRequestService)? {
        allServices.first { $0.id == id } as? PullRequestService
    }

    /// Creates an API object for each account so they can start with
    /// authorization and other state info.
    func initializeServices(with manager: AccountsManager) {
        for account in manager.accounts(ofType: .bitbucketServer) {
            _ = service(for: account)
        }
    }

    private static func accountKey(_ account: Account) -> String {
        if let host = account.location.host {
            return "\(account.user)@\(host)"
        }
        else {
            return account.user
        }
    }

    /// Notifies all services that an account has been updated
    func accountUpdated(oldAccount: Account, newAccount: Account) {
        for service in allServices {
            service.accountUpdated(oldAccount: oldAccount, newAccount: newAccount)
        }
    }

    func service(for account: Account) -> BasicAuthService? {
        let key = Services.accountKey(account)
        if let typeServices = services[account.type],
           let api = typeServices[key] {
            return api
        }
        else if let api = serviceMakers[account.type]?(account) {
            if services[account.type] != nil {
                services[account.type]![key] = api
            }
            else {
                services[account.type] = [key: api]
            }
            return api
        }
        return nil
    }

    func bitbucketServerAPI(for account: Account) -> BitbucketServerAPI? {
        service(for: account) as? BitbucketServerAPI
    }

    func createService<T>(for account: Account) -> T? where T: BasicAuthService {
        guard let password = tokenStorage.find(
            url: account.location,
            account: account.user
        )
        else {
            serviceLogger.info("No \(account.type.name) password for \(account.user)")
            return nil
        }

        guard let api = T(account: account, password: password)
        else { return nil }

        api.attemptAuthentication()
        return api
    }

    func pullRequestService(for remote: Remote) -> (any PullRequestService)? {
        let prServices = allServices.compactMap { $0 as? PullRequestService }
        return prServices.first { $0.match(remote: remote) }
    }
}


extension Services.Status: Equatable {
    // This doesn't come for free because of the associated value on .failed
    static func == (a: Services.Status, b: Services.Status) -> Bool {
        switch (a, b) {
        case (.unknown, .unknown),
            (.notStarted, .notStarted),
            (.inProgress, .inProgress),
            (.done, .done):
            return true
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
}


/// Protocol to be implemented by all concrete API classes.
protocol ServiceAPI {
    var type: AccountType { get }
}


public func XMLResponseTransformer(_ transformErrors: Bool = true) -> Siesta.ResponseTransformer {
    Siesta.ResponseContentTransformer<Data, XMLDocument>(transformErrors: transformErrors)
    { (entity: Siesta.Entity<Data>) throws -> XMLDocument? in
        try XMLDocument(
            data: entity.content,
            options: []
        )
    }
}
