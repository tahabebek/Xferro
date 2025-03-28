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
}

extension RemoteManagement {
    func remotes() -> [Remote] {
        return remoteNames().compactMap { remote(named: $0) }
    }
}
