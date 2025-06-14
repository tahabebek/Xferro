//
//  Repository+Tag.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

import Foundation

extension Repository {
    /// Load and return a list of all the `TagReference`s.
    func allTags() -> Result<[TagReference], NSError> {
        return references(withPrefix: .tagPrefix).map { (refs: [ReferenceType]) in
            return refs.map { $0 as! TagReference }
        }
    }

    /// Load the tag with the given OID.
    ///
    /// oid - The OID of the tag to look up.
    ///
    /// Returns the tag if it exists, or an error.
    func tag(_ oid: OID, staticLock: NSRecursiveLock? = nil) -> Result<Tag, NSError> {
        return withGitObject(oid, type: GIT_OBJECT_TAG, staticLock: staticLock) {
            Tag($0, lock: staticLock ?? lock)
        }
    }

    /// Load the tag with the given name (e.g., "tag-2").
    func tag(named name: String) -> Result<TagReference, NSError> {
        return reference(named: name.longTagRef).map { $0 as! TagReference }
    }

    func createTag(named name: String, oid: OID, force: Bool = false) -> Result<Void, NSError> {
        lock.lock()
        defer { lock.unlock() }
        return longOID(for: oid).flatMap { oid -> Result<Void, NSError> in
            var oid = oid.oid
            var object: OpaquePointer? = nil
            var result = git_object_lookup(&object, self.pointer, &oid, GIT_OBJECT_COMMIT)
            guard result == GIT_OK.rawValue else {
                return .failure(NSError(gitError: result, pointOfFailure: "git_object_lookup"))
            }
            result = git_tag_create_lightweight(&oid, self.pointer, name, object!, force ? 1 : 0)
            guard result == GIT_OK.rawValue else {
                return .failure(NSError(gitError: result, pointOfFailure: "git_tag_create_lightweight"))
            }
            return .success(())
        }
    }
}
