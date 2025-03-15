import Foundation

enum PreferenceKeys {
    static let fetchTags = "fetchTags"
    static let accounts = "accounts"
    static let autoCommitEnabled = "autoCommitEnabled"
    static let autoCommitAndPushEnabled = "autoCommitAndPushEnabled"
}

struct PreferenceKey<T> {
    let key: String
    let defaultValue: T

    init(_ key: String, _ value: T) {
        self.key = key
        self.defaultValue = value
    }
}

extension PreferenceKey: Sendable where T: Sendable {}

extension UserDefaults {
    subscript<T>(_ key: PreferenceKey<T>) -> T {
        get { value(forKey: key.key) as? T ?? key.defaultValue }
        set { setValue(newValue, forKey: key.key) }
    }

    subscript<T>(_ key: PreferenceKey<T>) -> T where T: RawRepresentable {
        get {
            (object(forKey: key.key) as? T.RawValue)
                .flatMap { .init(rawValue: $0) } ?? key.defaultValue
        }
        set { setValue(newValue.rawValue, forKey: key.key) }
    }

    @objc dynamic var autoCommitEnabled: Bool {
        get { bool(forKey: PreferenceKeys.autoCommitEnabled) }
        set { set(newValue, forKey: PreferenceKeys.autoCommitEnabled) }
    }

    @objc dynamic var autoCommitAndPushEnabled: Bool {
        get { bool(forKey: PreferenceKeys.autoCommitAndPushEnabled) }
        set { set(newValue, forKey: PreferenceKeys.autoCommitAndPushEnabled) }
    }

    var accounts: [Account] {
        get {
            guard let storedAccounts = array(forKey: PreferenceKeys.accounts)
                    as? [[String: AnyObject]]
            else { return [] }
            var result: [Account] = []

            for accountDict in storedAccounts {
                if let account = Account(dict: accountDict) {
                    result.append(account)
                }
                else {
                    serviceLogger.debug("Couldn't read account: \(accountDict.description)")
                }
            }
            return result
        }
        set {
            let accountsData = newValue.map { $0.plistDictionary }
            setValue(accountsData, forKey: PreferenceKeys.accounts)
        }
    }
}
