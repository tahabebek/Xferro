//
//  CommitIdentity.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

class CommitIdentity: Codable {
    let name: String
    let email: String

    init(name: String, email: String) {
        self.name = name
        self.email = email
    }
}
