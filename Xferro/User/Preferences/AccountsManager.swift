import Cocoa

final class AccountsManager: ObservableObject {
    static let shared = AccountsManager()

    let defaults: UserDefaults
    let tokenStorage: any TokenStorage

    @Published
    private(set) var accounts: [Account] = []

    init(tokenStorage: (any TokenStorage)? = nil) {
        self.tokenStorage = tokenStorage ?? KeychainStorage.shared
        self.defaults = .standard
        readAccounts()
    }

    func accounts(ofType type: AccountType) -> [Account] {
        accounts.filter { $0.type == type }
    }

    func add(_ account: Account, password: String) throws {
        if let existingPassword = tokenStorage.find(
            url: account.location,
            account: account.user
        ) {
            if existingPassword != password {
                try tokenStorage.change(
                    url: account.location,
                    newURL: nil,
                    account: account.user,
                    newAccount: nil,
                    password: password
                )
            }
        }
        else {
            try tokenStorage.save(
                url: account.location,
                account: account.user,
                password: password
            )
        }
        accounts.append(
            account
        )
    }

    func delete(account: Account) {
        if let index = accounts.firstIndex(where: { $0 == account }) {
            accounts.remove(at: index)
            // shut down the corresponding service object
        }
    }

    func modify(oldAccount: Account, newAccount: Account, newPassword: String?) throws {
        guard let index = accounts.firstIndex(where: { $0 == oldAccount })
        else {
            throw PasswordError.itemNotFound
        }
        let oldPassword = tokenStorage.find(
            url: oldAccount.location,
            account: oldAccount.user
        )
        let changePassword = newPassword != nil && newPassword != oldPassword

        if newAccount != oldAccount || changePassword {
            if let password = oldPassword {
                try tokenStorage
                    .change(
                        url: oldAccount.location,
                        newURL: newAccount.location,
                        account: oldAccount.user,
                        newAccount: newAccount.user,
                        password: newPassword ?? password
                    )
            } else if let password = newPassword {
                try tokenStorage
                    .save(
                        url: newAccount.location,
                        account: newAccount.user,
                        password: password
                    )
            } else {
                throw PasswordError.passwordNotSpecified
            }
        }
        accounts[index] = newAccount
    }

    /// Loads the accounts list from user defaults
    func readAccounts() {
        accounts = defaults.accounts
    }

    /// Writes the accounts list to user defaults
    func saveAccounts() {
        defaults.accounts = accounts
    }
}
