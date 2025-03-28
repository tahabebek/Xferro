//
//  NotificationNames.swift
//  Xferro
//
//  Created by Taha Bebek on 3/27/25.
//

import Foundation

extension Notification.Name {
    static let authenticationStatusChanged = Self("AuthStatusChanged")
    static let newRepositoryAdded = Self("NewRepositoryAdded")
    static let localRepositoryAdded = Self("LocalRepositoryAdded")
    static let repositoryCloneTapped = Self("RepositoryCloneTapped")
}

extension AnyHashable {
    static let repositoryURL = "repositoryURL"
}
