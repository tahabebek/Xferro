//
//  Tree.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import Foundation

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
