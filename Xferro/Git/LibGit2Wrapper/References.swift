//
//  References.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

extension String {
    static let tagPrefix = "refs/tags/"
    static let branchPrefix = "refs/heads/"
    static let remotePrefix = "refs/remotes/"

    var longBranchRef: String {
        return self.isLongRef ? self : "\(String.branchPrefix)\(self)"
    }

    var longTagRef: String {
        return self.isLongRef ? self : "\(String.tagPrefix)\(self)"
    }

    var isLongRef: Bool {
        return self.hasPrefix("refs/")
    }

    var isBranchRef: Bool {
        return self.hasPrefix(.branchPrefix)
    }

    var isTagRef: Bool {
        return self.hasPrefix(.tagPrefix)
    }

    var isRemoteRef: Bool {
        return self.hasPrefix(.remotePrefix)
    }

    var isHEAD: Bool {
        return self == "HEAD"
    }

    var shortRef: String {
        if !isLongRef { return self }
        let pieces = self.split(separator: "/")
        if pieces.count < 3 { return self }
        return pieces.dropFirst(2).joined(separator: "/")
    }
}

/// A reference to a git object.
protocol BaseReferenceType {
    /// The full name of the reference (e.g., `refs/heads/master`).
    var longName: String { get }

    /// The short human-readable name of the reference if one exists (e.g., `master`).
    var shortName: String? { get }
}

struct UnbornBranch: BaseReferenceType {

    /// The full name of the reference (e.g., `refs/heads/master`).
    var longName: String

    /// The short human-readable name of the reference if one exists (e.g., `master`).
    var shortName: String? {
        return name
    }

    var name: String

    /// Create an instance with a libgit2 `git_reference` object.
    ///
    /// Returns `nil` if the pointer isn't a branch.
    init?(_ pointer: OpaquePointer, unborn: Bool = false) {
        longName = String(validatingUTF8: git_reference_symbolic_target(pointer))!
        name = longName.split(separator: "/")[2...].joined(separator: "/")
    }

}

/// A reference to a git object.
protocol ReferenceType: BaseReferenceType {
    /// The OID of the referenced object.
    var oid: OID { get }
}

extension ReferenceType {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.longName == rhs.longName
        && lhs.oid == rhs.oid
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(longName)
        hasher.combine(oid)
    }
}

/// Create a Reference, Branch, or TagReference from a libgit2 `git_reference`.
 func referenceWithLibGit2Reference(_ pointer: OpaquePointer) -> ReferenceType {
    if git_reference_is_branch(pointer) != 0 || git_reference_is_remote(pointer) != 0 {
        return Branch(pointer)!
    } else if git_reference_is_tag(pointer) != 0 {
        return TagReference(pointer)!
    } else {
        return Reference(pointer)
    }
}

/// A generic reference to a git object.
struct Reference: ReferenceType, Hashable {
    /// The full name of the reference (e.g., `refs/heads/master`).
    let longName: String

    /// The short human-readable name of the reference if one exists (e.g., `master`).
    let shortName: String?

    /// The OID of the referenced object.
    let oid: OID

    /// Create an instance with a libgit2 `git_reference` object.
    init(_ pointer: OpaquePointer) {
        let shorthand = String(validatingUTF8: git_reference_shorthand(pointer))!
        longName = String(validatingUTF8: git_reference_name(pointer))!
        shortName = (shorthand == longName ? nil : shorthand)
        oid = OID(git_reference_target(pointer).pointee)
    }
}

/// A git branch.
struct Branch: ReferenceType, Hashable {
    /// The full name of the reference (e.g., `refs/heads/master`).
    let longName: String

    /// The short human-readable name of the branch (e.g., `master`).
    let name: String

    /// A pointer to the referenced commit.
    let commit: PointerTo<Commit>

    // MARK: Derived Properties

    /// The short human-readable name of the branch (e.g., `master`).
    ///
    /// This is the same as `name`, but is declared with an Optional type to adhere to
    /// `ReferenceType`.
    var shortName: String? {
        if isRemote,
           let index = name.range(of: "/")?.upperBound {
            let shortname = name[index...]
            return String(shortname)
        }
        return name
    }

    /// The OID of the referenced object.
    ///
    /// This is the same as `commit.oid`, but is declared here to adhere to `ReferenceType`.
    var oid: OID { return commit.oid }

    /// Whether the branch is a local branch.
    var isLocal: Bool { return longName.isBranchRef }

    /// Whether the branch is a remote branch.
    var isRemote: Bool { return longName.isRemoteRef }

    /// Whether the branch is a unborn branch. If it is unborn, the oid will be invalid.
    var isUnborn: Bool = false

    ///
    var isSymbolic: Bool = false

    /// The remote repository name if this is a remote branch.
    var remoteName: String? {
        if isRemote {
            let name = longName.split(separator: "/")[2]
            return String(name)
        }
        return nil
    }

    /// Create an instance with a libgit2 `git_reference` object.
    ///
    /// Returns `nil` if the pointer isn't a branch.
    init?(_ pointer: OpaquePointer) {
        longName = String(validatingUTF8: git_reference_name(pointer))!

        var namePointer: UnsafePointer<Int8>? = nil
        let success = git_branch_name(&namePointer, pointer)
        guard success == GIT_OK.rawValue else {
            return nil
        }
        name = String(validatingUTF8: namePointer!)!

        var oid: OID
        if git_reference_type(pointer).rawValue == GIT_REFERENCE_SYMBOLIC.rawValue {
            isSymbolic = true
            var resolved: OpaquePointer? = nil
            let success = git_reference_resolve(&resolved, pointer)
            guard success == GIT_OK.rawValue else {
                return nil
            }
            oid = OID(git_reference_target(resolved).pointee)
            git_reference_free(resolved)
        } else {
            oid = OID(git_reference_target(pointer).pointee)
        }
        commit = PointerTo<Commit>(oid)
    }
}

/// A git tag reference, which can be either a lightweight tag or a Tag object.
enum TagReference: ReferenceType, Hashable {
    /// A lightweight tag, which is just a name and an OID.
    case lightweight(String, OID)

    /// An annotated tag, which points to a Tag object.
    case annotated(String, Tag)

    /// The full name of the reference (e.g., `refs/tags/my-tag`).
    var longName: String {
        switch self {
        case let .lightweight(name, _):
            return name
        case let .annotated(name, _):
            return name
        }
    }

    /// The short human-readable name of the branch (e.g., `master`).
    var name: String {
        return longName.shortRef
    }

    /// The OID of the target object.
    ///
    /// If this is an annotated tag, the OID will be the tag's target.
    var oid: OID {
        switch self {
        case let .lightweight(_, oid):
            return oid
        case let .annotated(_, tag):
            return tag.target.oid
        }
    }

    // MARK: Derived Properties

    /// The short human-readable name of the branch (e.g., `master`).
    ///
    /// This is the same as `name`, but is declared with an Optional type to adhere to
    /// `ReferenceType`.
    var shortName: String? { return name }

    /// Create an instance with a libgit2 `git_reference` object.
    ///
    /// Returns `nil` if the pointer isn't a branch.
    init?(_ pointer: OpaquePointer) {
        if git_reference_is_tag(pointer) == 0 {
            return nil
        }

        let name = String(validatingUTF8: git_reference_name(pointer))!
        let repo = git_reference_owner(pointer)
        var oid = git_reference_target(pointer).pointee

        var pointer: OpaquePointer? = nil
        let result = git_object_lookup(&pointer, repo, &oid, GIT_OBJECT_TAG)
        if result == GIT_OK.rawValue {
            self = .annotated(name, Tag(pointer!))
        } else {
            self = .lightweight(name, OID(oid))
        }
        git_object_free(pointer)
    }
}
