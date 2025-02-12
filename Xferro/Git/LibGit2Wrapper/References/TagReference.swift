//
//  TagReference.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import Foundation

/// A git tag reference, which can be either a lightweight tag or a Tag object.
enum TagReference: ReferenceType, Hashable, Identifiable {
    var id: String { longName }
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
    init?(_ pointer: OpaquePointer, lock: NSRecursiveLock) {
        lock.lock()
        defer { lock.unlock() }
        if git_reference_is_tag(pointer) == 0 {
            return nil
        }

        let name = String(validatingCString: git_reference_name(pointer))!
        let repo = git_reference_owner(pointer)
        var oid = git_reference_target(pointer).pointee

        var pointer: OpaquePointer? = nil
        let result = git_object_lookup(&pointer, repo, &oid, GIT_OBJECT_TAG)
        if result == GIT_OK.rawValue {
            self = .annotated(name, Tag(pointer!, lock: lock))
        } else {
            self = .lightweight(name, OID(oid))
        }
        git_object_free(pointer)
    }
}

extension TagReference: Codable {
    private enum CodingKeys: String, CodingKey {
        case type, name, oid, tag
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .lightweight(name, oid):
            try container.encode("lightweight", forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encode(oid, forKey: .oid)
        case let .annotated(name, tag):
            try container.encode("annotated", forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encode(tag, forKey: .tag)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let name = try container.decode(String.self, forKey: .name)

        switch type {
        case "lightweight":
            let oid = try container.decode(OID.self, forKey: .oid)
            self = .lightweight(name, oid)
        case "annotated":
            let tag = try container.decode(Tag.self, forKey: .tag)
            self = .annotated(name, tag)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid tag type")
        }
    }
}
