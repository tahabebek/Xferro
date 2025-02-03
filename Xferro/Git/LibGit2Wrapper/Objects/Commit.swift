//
//  Commit.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import Foundation

/// A git commit.
struct Commit: ObjectType, Hashable, Codable, CustomStringConvertible, Identifiable {
    var id: OID { oid }
    static let type = GitObjectType.commit

    /// The OID of the commit.
    let oid: OID

    /// The OID of the commit's tree.
    let tree: PointerTo<Tree>

    /// The OIDs of the commit's parents.
    let parents: [PointerTo<Commit>]

    /// The author of the commit.
    let author: Signature

    /// The committer of the commit.
    let committer: Signature

    /// The full message of the commit.
    let message: String

    /// Summary
    let summary: String

    /// Create an instance with a libgit2 `git_commit` object.
    init(_ pointer: OpaquePointer) {
        oid = OID(git_object_id(pointer).pointee)
        message = String(validatingUTF8: git_commit_message(pointer))!
        summary = String(validatingUTF8: git_commit_summary(pointer))!
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
