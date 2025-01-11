//
//  Users.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import Foundation

class Users: Codable {
    let currentUser: User?
    let recentUsers: Set<User>

    init(currentUser: User?, recentUsers: Set<User>) {
        self.currentUser = currentUser
        self.recentUsers = recentUsers
    }
}
