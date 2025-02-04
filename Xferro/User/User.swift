//
//  User.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import Foundation
import Observation

@Observable class User: Codable, Hashable, Equatable {
    typealias UserID = String
    let userID: UserID
    let login: Login
    let commitIdentity: CommitIdentity
    var projects: [Project]

    static func == (lhs: User, rhs: User) -> Bool {
        lhs.userID == rhs.userID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(userID)
    }

    init(userID: UserID, login: Login, commitIdentity: CommitIdentity, projects: [Project] = []) {
        self.userID = userID
        self.login = login
        self.commitIdentity = commitIdentity
        self.projects = projects
    }
}
