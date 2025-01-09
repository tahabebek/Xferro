//
//  User.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import Foundation

struct User: Codable {
    typealias UserID = String
    let userID: UserID
    let login: Login
    let commitIdentity: CommitIdentity
    let projects: Projects
}
