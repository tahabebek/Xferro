//
//  Account.swift
//  Xferro
//
//  Created by Taha Bebek on 3/14/25.
//

struct Account: Identifiable {
    var type: AccountType
    var user: String
    var location: URL
    let id: UUID

    /// Account fields as stored in preferences
    enum Keys {
        static let user = "user"
        static let location = "location"
        static let type = "type"
    }

    var plistDictionary: NSDictionary {
        let accountDict = NSMutableDictionary(capacity: 3)
        accountDict[Keys.type] = type.name
        accountDict[Keys.user] = user
        accountDict[Keys.location] = location.absoluteString
        return accountDict
    }

    init(type: AccountType, user: String, location: URL, id: UUID) {
        self.type = type
        self.user = user
        self.location = location
        self.id = id
    }

    init?(dict: [String: AnyObject]) {
        guard let type = AccountType(name: dict[Keys.type] as? String),
              let user = dict[Keys.user] as? String,
              let location = dict[Keys.location] as? String,
              let url = URL(string: location)
        else { return nil }

        self.init(type: type, user: user, location: url, id: .init())
    }
}

extension Account: Equatable {
    static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.type == rhs.type &&
        lhs.user == rhs.user &&
        lhs.location == rhs.location
    }
}
