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
    private(set) var projects: [Project]
    var lastSelectedRepositoryPath: String?

    static func == (lhs: User, rhs: User) -> Bool {
        lhs.userID == rhs.userID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(userID)
    }

    init(
        userID: UserID,
        login: Login,
        commitIdentity: CommitIdentity,
        projects: [Project] = [],
        lastSelectedRepositoryPath: String? = nil
    ) {
        self.userID = userID
        self.login = login
        self.commitIdentity = commitIdentity
        self.projects = projects
        self.lastSelectedRepositoryPath = lastSelectedRepositoryPath
    }

    func addProject(_ project: Project) -> Bool {
        if projects.filter({ $0.url == project.url }).count > 0 {
            return false
        }
        projects.append(project)
        return true
    }

    func removeProject(_ url: URL) {
        projects.removeAll { $0.url == url }
    }
}
