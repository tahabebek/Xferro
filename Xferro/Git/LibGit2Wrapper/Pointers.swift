//
//  Pointer.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

/// A pointer to a git object.
protocol PointerType: Hashable {
    /// The OID of the referenced object.
    var oid: OID { get }

    /// The libgit2 `git_object_t` of the referenced object.
    var type: GitObjectType { get }
}

extension PointerType {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.oid == rhs.oid
        && lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(oid)
    }
}

/// A pointer to a git object.
enum Pointer: PointerType {
    case commit(OID)
    case tree(OID)
    case blob(OID)
    case tag(OID)

    var oid: OID {
        switch self {
        case let .commit(oid):
            return oid
        case let .tree(oid):
            return oid
        case let .blob(oid):
            return oid
        case let .tag(oid):
            return oid
        }
    }

    var type: GitObjectType {
        switch self {
        case .commit:
            return .commit
        case .tree:
            return .tree
        case .blob:
            return .blob
        case .tag:
            return .tag
        }
    }

    /// Create an instance with an OID and a libgit2 `git_object_t`.
    init?(oid: OID, type: git_object_t) {
        switch type {
        case GIT_OBJECT_COMMIT:
            self = .commit(oid)
        case GIT_OBJECT_TREE:
            self = .tree(oid)
        case GIT_OBJECT_BLOB:
            self = .blob(oid)
        case GIT_OBJECT_TAG:
            self = .tag(oid)
        default:
            return nil
        }
    }
}

extension Pointer: CustomStringConvertible {
    var description: String {
        switch self {
        case .commit:
            return "commit(\(oid))"
        case .tree:
            return "tree(\(oid))"
        case .blob:
            return "blob(\(oid))"
        case .tag:
            return "tag(\(oid))"
        }
    }
}

struct PointerTo<T: ObjectType>: PointerType, Codable {
    let oid: OID

    var type: GitObjectType {
        return T.type
    }

    init(_ oid: OID) {
        self.oid = oid
    }
}
