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
    func loadUsers() {
        users = DataManager.load(Users.self, filename: DataManager.usersFileName)
    }
}
