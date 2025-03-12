//
//  FileDiffer.swift
//  Xferro
//
//  Created by Taha Bebek on 2/25/25.
//

import Foundation
import UniformTypeIdentifiers

extension Repository {
    static let textNames = ["AUTHORS", "CONTRIBUTING", "COPYING", "LICENSE", "Makefile", "README"]

    enum FileContext
    {
        case commit(Commit)
        case index
        case workspace
    }

    func diffMaker(oldNewFile: OldNewFile, commitOID: OID, parentOID: OID?) -> PatchMaker.PatchResult?
    {
        switch oldNewFile.status {
        case .unmodified:
            return .noDifference
        case .added, .copied, .untracked, .modified:
            guard let newFile = oldNewFile.new else {
                fatalError(.invalid)
            }
            let toCommit = commit(commitOID).mustSucceed()

            let parentCommit = parentOID.flatMap { commit($0).mustSucceed() }
            guard isTextFile(newFile, context: .commit(toCommit)) ||
                    parentCommit.map({ isTextFile(newFile, context: .commit($0)) }) ?? false
            else { return .binary }

            let toSource: PatchMaker.SourceType = if let toBlob = blob(commit: toCommit, path: newFile) {
                .blob(toBlob)
            } else {
                .data(Data())
            }

            let fromSource: PatchMaker.SourceType =
            if let parentCommit, let fromBlob = blob(commit: parentCommit, path: newFile) {
                .blob(fromBlob)
            } else {
                .data(Data())
            }

            return .diff(PatchMaker(repository: self, from: fromSource, to: toSource, path: newFile))
        case .deleted:
            guard let oldFile = oldNewFile.old else {
                fatalError(.invalid)
            }
            let toCommit = commit(commitOID).mustSucceed()

            let parentCommit = parentOID.flatMap { commit($0).mustSucceed() }
            guard isTextFile(oldFile, context: .commit(toCommit)) ||
                    parentCommit.map({ isTextFile(oldFile, context: .commit($0)) }) ?? false
            else { return .binary }

            let toSource: PatchMaker.SourceType = if let toBlob = blob(commit: toCommit, path: oldFile) {
                .blob(toBlob)
            } else {
                .data(Data())
            }

            let fromSource: PatchMaker.SourceType =
            if let parentCommit, let fromBlob = blob(commit: parentCommit, path: oldFile) {
                .blob(fromBlob)
            } else {
                .data(Data())
            }

            return .diff(PatchMaker(repository: self, from: fromSource, to: toSource, path: oldFile))
        case .renamed, .typeChange:
            guard let oldFile = oldNewFile.old,
                  let newFile = oldNewFile.new else {
                fatalError(.invalid)
            }
            let toCommit = commit(commitOID).mustSucceed()

            let parentCommit = parentOID.flatMap { commit($0).mustSucceed() }
            guard isTextFile(newFile, context: .commit(toCommit)) ||
                    parentCommit.map({ isTextFile(oldFile, context: .commit($0)) }) ?? false
            else { return .binary }

            let toSource: PatchMaker.SourceType = if let toBlob = blob(commit: toCommit, path: newFile) {
                .blob(toBlob)
            } else {
                .data(Data())
            }

            let fromSource: PatchMaker.SourceType =
            if let parentCommit, let fromBlob = blob(commit: parentCommit, path: oldFile) {
                .blob(fromBlob)
            } else {
                .data(Data())
            }

            return .diff(PatchMaker(repository: self, from: fromSource, to: toSource, path: newFile))
        case .ignored, .unreadable:
            return nil
        case .conflicted:
            fatalError(.unimplemented)
        }
    }

    /// Returns a diff maker for a file in the index, compared to HEAD
    func stagedDiff(head: Head, oldNewFile: OldNewFile) -> PatchMaker.PatchResult
    {
        switch oldNewFile.status {
        case .unmodified:
            return .noDifference
        case .added, .copied, .untracked:
            guard let newFile = oldNewFile.new else {
                fatalError(.invalid)
            }
            guard isTextFile(newFile, context: .workspace) else {
                return .binary
            }
            let indexBlob = stagedBlob(file: newFile)
            return .diff(PatchMaker(
                repository: self,
                from: .data(Data()),
                to: PatchMaker.SourceType(indexBlob),
                path: newFile)
            )
        case .deleted:
            guard let oldFile = oldNewFile.old else {
                fatalError(.invalid)
            }
            guard isTextFile(oldFile, context: .workspace) else {
                return .binary
            }
            let indexBlob = stagedBlob(file: oldFile)
            let headBlob = fileBlob(head: head, path: oldFile)
            return .diff(PatchMaker(
                repository: self,
                from: PatchMaker.SourceType(headBlob),
                to: PatchMaker.SourceType(indexBlob),
                path: oldFile)
            )
        case .modified:
            guard let newFile = oldNewFile.new else {
                fatalError(.invalid)
            }
            guard isTextFile(newFile, context: .workspace) else {
                return .binary
            }
            let indexBlob = stagedBlob(file: newFile)
            let headBlob = fileBlob(head: head, path: newFile)
            return .diff(PatchMaker(
                repository: self,
                from: PatchMaker.SourceType(headBlob),
                to: PatchMaker.SourceType(indexBlob),
                path: newFile)
            )
        case .renamed, .typeChange:
            guard let oldFile = oldNewFile.old,
                  let newFile = oldNewFile.new else {
                fatalError(.invalid)
            }
            let indexBlob = stagedBlob(file: newFile)
            let headBlob = fileBlob(head: head, path: oldFile)
            return .diff(PatchMaker(
                repository: self,
                from: PatchMaker.SourceType(headBlob),
                to: PatchMaker.SourceType(indexBlob),
                path: newFile)
             )
        case .ignored, .unreadable:
            fatalError(.invalid)
        case .conflicted:
            fatalError(.unimplemented)
        }
    }

    /// Returns a diff maker for a file in the index, compared to HEAD-1.
    func amendingStagedDiff(head: Head, file: String) -> PatchMaker.PatchResult?
    {
        guard isTextFile(file, context: .index)
        else { return .binary }

        let blob = head.commit.parents.map(\.oid).first
            .flatMap { oid in
                fileBlob(head: head, path: file)
            }
        let indexBlob = stagedBlob(file: file)

        return .diff(PatchMaker(
            repository: self,
            from: PatchMaker.SourceType(blob),
            to: PatchMaker.SourceType(indexBlob),
            path: file)
        )
    }

    /// Returns a diff maker for a file in the workspace, compared to the index.
    func unstagedDiff(head: Head, oldNewFile: OldNewFile) -> PatchMaker.PatchResult
    {
        switch oldNewFile.status {
        case .unmodified:
            return .noDifference
        case .added, .copied, .untracked:
            guard let newFile = oldNewFile.new else {
                fatalError(.invalid)
            }
            guard isTextFile(newFile, context: .workspace) else {
                return .binary
            }
            let newFileData = try! Data(contentsOf: URL(filePath: oldNewFile.new!))
            return .diff(PatchMaker(
                repository: self,
                from: .data(Data()),
                to: .data(newFileData),
                path: newFile)
            )
        case .deleted:
            guard let oldFile = oldNewFile.old else {
                fatalError(.invalid)
            }
            guard isTextFile(oldFile, context: .workspace) else {
                return .binary
            }
            let headBlob = fileBlob(head: head, path: oldFile)
            return .diff(PatchMaker(
                repository: self,
                from: PatchMaker.SourceType(headBlob),
                to: .data(Data()),
                path: oldFile)
            )
        case .modified:
            guard let newFile = oldNewFile.new else {
                fatalError(.invalid)
            }
            guard isTextFile(newFile, context: .workspace) else {
                return .binary
            }
            guard let newFileData = try? Data(contentsOf: URL(filePath: oldNewFile.new!)) else {
                fatalError(.invalid)
            }
            let headBlob = fileBlob(head: head, path: newFile)
            return .diff(PatchMaker(
                repository: self,
                from: PatchMaker.SourceType(headBlob),
                to: .data(newFileData),
                path: newFile)
            )
        case .renamed, .typeChange:
            guard let oldFile = oldNewFile.old,
                  let newFile = oldNewFile.new else {
                fatalError(.invalid)
            }
            let newFileData = try! Data(contentsOf: URL(filePath: oldNewFile.new!))
            let headBlob = fileBlob(head: head, path: oldFile)
            return .diff(PatchMaker(
                repository: self,
                from: PatchMaker.SourceType(headBlob),
                to: .data(newFileData),
                path: newFile)
            )
        case .ignored, .unreadable:
            fatalError(.invalid)
        case .conflicted:
            fatalError(.unimplemented)
        }
    }

    func blame(for path: String, from startOID: OID?, to endOID: OID?) -> Blame?
    {
        Blame(repository: self, path: path, from: startOID, to: endOID)
    }

    func blame(for path: String, data fromData: Data?, to endOID: OID?) -> Blame?
    {
        Blame(repository: self, path: path, data: fromData ?? Data(), to: endOID)
    }

    func stagedBlob(file: String) -> Blob?
    {
        let index = index().mustSucceed()
        guard let entryOID = index.entry(at: file)?.oid else { return nil }
        return withGitObject(entryOID, type: GIT_OBJECT_BLOB) {
            Blob($0, lock: lock)
        }.mustSucceed()
    }

    func fileBlob(head: Head, path: String) -> Blob?
    {
        commitBlob(commit: head.commit, path: path)
    }

    func commitBlob(commit: Commit, path: String) -> Blob?
    {
        var treePointer: OpaquePointer? = nil
        var git_oid = commit.tree.oid.oid
        let result = git_object_lookup_prefix(&treePointer, self.pointer, &git_oid, commit.tree.oid.length, GIT_OBJECT_TREE)

        guard result == GIT_OK.rawValue, let treePointer else {
            let err = NSError(gitError: result, pointOfFailure: "git_object_lookup_prefix")
            fatalError(err.localizedDescription)
        }

        guard let toEntry = Tree.entry(tree: treePointer, path: path) else {
            return nil
        }

        if case .blob(let oid) = toEntry.object {
            return withGitObject(oid, type: GIT_OBJECT_BLOB) {
                Blob($0, lock: lock)
            }.mustSucceed()
        }
        return nil
    }

    /// Returns true if the file seems to be text, based on its name or its content.
    /// - parameter path: File path relative to the repository
    /// - parameter context: Where to look for the specified file
    func isTextFile(_ path: String, context: FileContext) -> Bool
    {
        let name = (path as NSString).lastPathComponent
        guard !name.isEmpty
        else { return false }

        if Self.textNames.contains(name) {
            return true
        }
        if Self.isTextExtension(name) {
            return true
        }

        switch context {
        case .commit(let commit):
            if let blob = blob(commit: commit, path: path) {
                return !blob.isBinary
            }
        case .index:
            let index = index().mustSucceed()
            guard let entryOID = index.entry(at: path)?.oid else { return false }
            let blob = withGitObject(entryOID, type: GIT_OBJECT_BLOB) {
                Blob($0, lock: lock)
            }.mustSucceed()
            return !blob.isBinary
        case .workspace:
            let url = self.fileURL(path)
            guard let data = try? Data(contentsOf: url)
            else { return false }

            return !data.isBinary()
        }

        return false
    }

    static func isTextExtension(_ name: String) -> Bool
    {
        let ext = (name as NSString).pathExtension
        guard !ext.isEmpty,
              let type = UTType(filenameExtension: ext)
        else { return false }

        return type.conforms(to: .text)
    }

    func fileURL(_ file: String) -> URL
    {
        return workDir.appendingPathComponent(file)
    }

    func blob(commit: Commit, path: String) -> Blob? {
        var treePointer: OpaquePointer? = nil
        var git_oid = commit.oid.oid
        let result = git_object_lookup_prefix(&treePointer, self.pointer, &git_oid, commit.oid.length, GIT_OBJECT_TREE)

        guard result == GIT_OK.rawValue, let treePointer else {
            let err = NSError(gitError: result, pointOfFailure: "git_object_lookup_prefix")
            fatalError(err.localizedDescription)
        }
        guard let toEntry = Tree.entry(tree: treePointer, path: path) else {
            let err = NSError(gitError: result, pointOfFailure: "Tree.entry")
            fatalError(err.localizedDescription)
        }

        if case .blob(let oid) = toEntry.object {
            return withGitObject(oid, type: GIT_OBJECT_BLOB) {
                Blob($0, lock: lock)
            }.mustSucceed()
        }
        return nil
    }
}
