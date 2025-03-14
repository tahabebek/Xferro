//
//  AccountInfo.swift
//  Xferro
//
//  Created by Taha Bebek on 3/14/25.
//

class AccountInfo: ObservableObject, Identifiable {
    @Published var serviceType: AccountType
    @Published var location: String
    @Published var userName: String
    @Published var password: String
    let id: UUID

    init() {
        self.serviceType = .allCases.first!
        self.location = ""
        self.userName = ""
        self.password = ""
        self.id = .init()
    }

    init(with account: Account, password: String) {
        self.serviceType = account.type
        self.location = account.location.absoluteString
        self.userName = account.user
        self.password = password
        self.id = account.id
    }
}

extension AccountInfo: Validating {
    var isValid: Bool {
        !userName.isEmpty &&
        (!serviceType.needsLocation || URL(string: location) != nil)
    }
}
