//
//  Objects.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

import Foundation

enum GitObjectType: Int32 {
    case any         = -2 /**< GIT_OBJECT_ANY, Object can be any of the following */
    case invalid     = -1 /**< GIT_OBJECT_INVALID, Object is invalid. */
    case commit      = 1 /**< GIT_OBJECT_COMMIT, A commit object. */
    case tree        = 2 /**< GIT_OBJECT_TREE, A tree (directory listing) object. */
    case blob        = 3 /**< GIT_OBJECT_BLOB, A file revision object. */
    case tag         = 4 /**< GIT_OBJECT_TAG, An annotated tag object. */
    case offsetDelta = 6 /**< GIT_OBJECT_OFS_DELTA, A delta, base is given by an offset. */
    case refDelta    = 7 /**< GIT_OBJECT_REF_DELTA, A delta, base is given by object id. */

    var git_type: git_object_t {
        return git_object_t(rawValue: self.rawValue)
    }
}

/// A git object.
protocol ObjectType {
    static var type: GitObjectType { get }

    /// The OID of the object.
    var oid: OID { get }

    /// Create an instance with the underlying libgit2 type.
    init(_ pointer: OpaquePointer)
}

extension ObjectType {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.oid == rhs.oid
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(oid)
    }
}

struct Signature {
    /// The name of the person.
    let name: String

    /// The email of the person.
    let email: String

    /// The time when the action happened.
    let time: Date

    /// The time zone that `time` should be interpreted relative to.
    let timeZone: TimeZone

    /// Create an instance with custom name, email, dates, etc.
    init(name: String, email: String, time: Date = Date(), timeZone: TimeZone = TimeZone.autoupdatingCurrent) {
        self.name = name
        self.email = email
        self.time = time
        self.timeZone = timeZone
    }

    /// Create an instance with a libgit2 `git_signature`.
    init(_ signature: git_signature) {
        name = String(validatingUTF8: signature.name)!
        email = String(validatingUTF8: signature.email)!
        time = Date(timeIntervalSince1970: TimeInterval(signature.when.time))
        timeZone = TimeZone(secondsFromGMT: 60 * Int(signature.when.offset))!
    }

    /// Return an unsafe pointer to the `git_signature` struct.
    /// Caller is responsible for freeing it with `git_signature_free`.
    func makeUnsafeSignature() -> Result<UnsafeMutablePointer<git_signature>, NSError> {
        var signature: UnsafeMutablePointer<git_signature>? = nil
        let time = git_time_t(self.time.timeIntervalSince1970)    // Unix epoch time
        let offset = Int32(timeZone.secondsFromGMT(for: self.time) / 60)
        let signatureResult = git_signature_new(&signature, name, email, time, offset)
        guard signatureResult == GIT_OK.rawValue, let signatureUnwrap = signature else {
            let err = NSError(gitError: signatureResult, pointOfFailure: "git_signature_new")
            return .failure(err)
        }
        return .success(signatureUnwrap)
    }

    static func `default`(_ repository: Repository) -> Result<Signature, NSError> {
        var signature: UnsafeMutablePointer<git_signature>? = nil
        let signatureResult = git_signature_default(&signature, repository.pointer)
        if signatureResult == GIT_OK.rawValue, let signatureUnwrap = signature {
            let s = signatureUnwrap.move()
            return .success(Signature(s))
        }
        guard signatureResult == GIT_ENOTFOUND.rawValue else {
            let err = NSError(gitError: signatureResult, pointOfFailure: "git_signature_default")
            return .failure(err)
        }
        let name = (try? repository.config.string(for: "user.name").get()) ?? NSUserName()
        let email = (try? repository.config.string(for: "user.email").get()) ?? "\(NSUserName())@\(ProcessInfo.processInfo.hostName)"
        return .success(Signature(name: name, email: email))
    }
}

extension Signature: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(email)
        hasher.combine(time)
    }
}

/// A git commit.
struct Commit: ObjectType, Hashable, CustomStringConvertible {
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

    /// Create an instance with a libgit2 `git_commit` object.
    init(_ pointer: OpaquePointer) {
        oid = OID(git_object_id(pointer).pointee)
        message = String(validatingUTF8: git_commit_message(pointer))!
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

/// A git tree.
struct Tree: ObjectType, Hashable {
    static let type = GitObjectType.tree

    /// An entry in a `Tree`.
    struct Entry: Hashable {
        /// The entry's UNIX file attributes.
        let attributes: Int32

        /// The object pointed to by the entry.
        let object: Pointer

        /// The file name of the entry.
        let name: String

        /// Create an instance with a libgit2 `git_tree_entry`.
        init(_ pointer: OpaquePointer) {
            let oid = OID(git_tree_entry_id(pointer).pointee)
            attributes = Int32(git_tree_entry_filemode(pointer).rawValue)
            object = Pointer(oid: oid, type: git_tree_entry_type(pointer))!
            name = String(validatingUTF8: git_tree_entry_name(pointer))!
        }

        /// Create an instance with the individual values.
        init(attributes: Int32, object: Pointer, name: String) {
            self.attributes = attributes
            self.object = object
            self.name = name
        }
    }

    /// The OID of the tree.
    let oid: OID

    /// The entries in the tree.
    let entries: [String: Entry]

    /// Create an instance with a libgit2 `git_tree`.
    init(_ pointer: OpaquePointer) {
        oid = OID(git_object_id(pointer).pointee)

        var entries: [String: Entry] = [:]
        for idx in 0..<git_tree_entrycount(pointer) {
            let entry = Entry(git_tree_entry_byindex(pointer, idx)!)
            entries[entry.name] = entry
        }
        self.entries = entries
    }
}

extension Tree.Entry: CustomStringConvertible {
    var description: String {
        return "\(attributes) \(object) \(name)"
    }
}

/// A git blob.
struct Blob: ObjectType, Hashable {
    static let type = GitObjectType.blob

    /// The OID of the blob.
    let oid: OID

    /// The contents of the blob.
    let data: Data

    /// Create an instance with a libgit2 `git_blob`.
    init(_ pointer: OpaquePointer) {
        oid = OID(git_object_id(pointer).pointee)

        let length = Int(git_blob_rawsize(pointer))
        data = Data(bytes: git_blob_rawcontent(pointer), count: length)
    }
}

/// An annotated git tag.
struct Tag: ObjectType, Hashable {
    static let type = GitObjectType.tag

    /// The OID of the tag.
    let oid: OID

    /// The tagged object.
    let target: Pointer

    /// The name of the tag.
    let name: String

    /// The tagger (author) of the tag.
    let tagger: Signature

    /// The message of the tag.
    let message: String

    /// Create an instance with a libgit2 `git_tag`.
    init(_ pointer: OpaquePointer) {
        oid = OID(git_object_id(pointer).pointee)
        let targetOID = OID(git_tag_target_id(pointer).pointee)
        target = Pointer(oid: targetOID, type: git_tag_target_type(pointer))!
        name = String(validatingUTF8: git_tag_name(pointer))!
        tagger = Signature(git_tag_tagger(pointer).pointee)
        message = String(validatingUTF8: git_tag_message(pointer))!
    }
}

