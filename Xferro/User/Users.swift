//
//  Users.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import Foundation

struct Users: Codable {
    let currentUser: User?
    let recentUsers: [User]
}
