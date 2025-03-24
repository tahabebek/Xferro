//
//  Commit.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import Foundation

struct Commit: ObjectType, Hashable, Codable, CustomStringConvertible, Identifiable {
    var id: String { oid.description }
    static let type = GitObjectType.commit

    let oid: OID
    let tree: PointerTo<Tree>
    let parents: [PointerTo<Commit>]
    let author: Signature
    let committer: Signature
    let message: String
    let summary: String

    init(_ pointer: OpaquePointer, lock: NSRecursiveLock) {
        lock.lock()
        defer { lock.unlock() }
        oid = OID(git_object_id(pointer).pointee)
        message = String(validatingCString: git_commit_message(pointer))!
        summary = String(validatingCString: git_commit_summary(pointer))!
        author = Signature(git_commit_author(pointer).pointee)
        committer = Signature(git_commit_committer(pointer).pointee)
        tree = PointerTo(OID(git_commit_tree_id(pointer).pointee))

        self.parents = (0..<git_commit_parentcount(pointer)).map {
            return PointerTo(OID(git_commit_parent_id(pointer, $0).pointee))
        }
    }

    var description: String {
        var info = ["Commit: \(oid)"]
        info.append("Parents: \(parents.map { $0.oid.desc(length: 10) }.joined(separator: ", "))")
        info.append("Author: \(author.name) <\(author.email)>")
        info.append("Date: \(author.time.description(with: .autoupdatingCurrent))")
        if author.email != committer.email {
            info.append("Committer: \(committer.name) <\(committer.email)>")
        }
        info.append("Message: \(message)")
        return info.joined(separator: "\n")
    }
}
