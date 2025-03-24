//
//  Tree.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import Foundation

struct Tree: ObjectType, Hashable {
    static let type = GitObjectType.tree

    struct Entry: Hashable {
        let attributes: Int32
        let object: Pointer
        let owner: Pointer
        let owned: Bool
        let name: String

        init(
            _ pointer: OpaquePointer,
            owner: Pointer,
            owned: Bool
        ) {
            let oid = OID(git_tree_entry_id(pointer).pointee)
            self.attributes = Int32(git_tree_entry_filemode(pointer).rawValue)
            self.object = Pointer(oid: oid, type: git_tree_entry_type(pointer))!
            self.owner = owner
            self.owned = owned
            self.name = String(validatingCString: git_tree_entry_name(pointer))!
        }
    }

    let oid: OID

    init(_ pointer: OpaquePointer, lock: NSRecursiveLock) {
        lock.lock()
        defer { lock.unlock() }
        oid = OID(git_object_id(pointer).pointee)
    }

    static func entry(tree: OpaquePointer, path: String) -> Entry? {
        guard let owner = git_tree_owner(tree),
              let entry = try? OpaquePointer.from({
                  git_tree_entry_bypath(&$0, tree, path)
              })
        else { return nil }

        return Entry(entry, owner: Pointer.tree(OID(git_object_id(owner).pointee)), owned: true)
    }
}

extension Tree.Entry: CustomStringConvertible {
    var description: String {
        return "\(attributes) \(object) \(name)"
    }
}
