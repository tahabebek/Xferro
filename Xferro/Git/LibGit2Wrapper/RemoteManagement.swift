//
//  RemoteManagement.swift
//  Xferro
//
//  Created by Taha Bebek on 3/14/25.
//

protocol RemoteManagement: AnyObject {
    associatedtype Remote: Xferro.Remote

    func remoteNames() -> [String]
    func remote(named name: String) -> Remote?
    func addRemote(named name: String, url: URL) throws
    func deleteRemote(named name: String) throws

    /// Pushes an update for the given branch.
    /// - parameter branches: Local branches to push; must have a tracking branch set
    /// - parameter remote: Target remote to push to
    /// - parameter callbacks: Password and progress callbacks
    func push(branches: [String], remote: Remote, callbacks: RemoteCallbacks, force: Bool) throws

    /// Dowloads updated refs and commits from the remote.
    func fetch(remote: Remote, options: FetchOptions) throws

    /// Initiates pulling (fetching and merging) the given branch.
    /// - parameter branch: Either the local branch or the remote tracking branch.
    /// - parameter remote: The remote to pull from.
    /// - parameter options: Options for the fetch operation.
    func pull(branch: Branch, remote: Remote, options: FetchOptions) throws
}

extension RemoteManagement {
    func remotes() -> [Remote] {
        return remoteNames().compactMap { remote(named: $0) }
    }
}
