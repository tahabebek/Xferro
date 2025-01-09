//
//  UsersLoader.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import Foundation
import Observation

@Observable class UsersLoader {
    var users: Users?

    static let hardCodedCommit: Commit = Commit(files: [File(name: "xferro.swift")])
    static let hardCodedProject: Project = Project(isGit: true, url: URL(string: "https://github.com/tsbebek/Xferro")!, commits: [hardCodedCommit])
    static let hardCodedCommitIdentity: CommitIdentity = CommitIdentity(name: "Taha Bebek", email: "tsbebek@gmail.com")
    static let hardCodedUser = User(
        userID: "1",
        login: .email,
        commitIdentity: hardCodedCommitIdentity,
        projects:
            Projects(
                currentProject: hardCodedProject,
                projects: [hardCodedProject]
            )
    )

    static let hardCodedUserNoProjects = User(
        userID: "1",
        login: .email,
        commitIdentity: hardCodedCommitIdentity,
        projects:
            Projects(
                currentProject: nil,
                projects: []
            )
    )

    func loadUsers() async throws {
        users = Users(currentUser: Self.hardCodedUser, recentUsers: [Self.hardCodedUser])
    }

    func loadUsersNil() async throws {
        users = nil
    }

    func loadUsersNoCurrentProject() async throws {
        users = Users(currentUser: nil, recentUsers: [Self.hardCodedUser])
    }
}
