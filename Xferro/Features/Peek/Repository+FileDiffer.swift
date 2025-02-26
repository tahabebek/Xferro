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

    func diffMaker(forFile file: String, commitOID: OID, parentOID: OID?) -> PatchMaker.PatchResult?
    {
        let toCommit = commit(commitOID).mustSucceed()

        let parentCommit = parentOID.flatMap { commit($0).mustSucceed() }
        guard isTextFile(file, context: .commit(toCommit)) ||
                parentCommit.map({ isTextFile(file, context: .commit($0)) }) ?? false
        else { return .binary }

        let toSource: PatchMaker.SourceType = if let toBlob = blob(commit: toCommit, path: file) {
            .blob(toBlob)
        } else {
            .data(Data())
        }

        let fromSource: PatchMaker.SourceType =
        if let parentCommit, let fromBlob = blob(commit: parentCommit, path: file) {
            .blob(fromBlob)
        } else {
            .data(Data())
        }

        return .diff(PatchMaker(repository: self, from: fromSource, to: toSource, path: file))
    }

    /// Returns a diff maker for a file in the index, compared to HEAD
    func stagedDiff(head: Head, oldFile: String?, newFile: String?) -> PatchMaker.PatchResult?
    {
        if let oldFile, let newFile {
            guard isTextFile(oldFile, context: .workspace), isTextFile(newFile, context: .workspace)
            else { return .binary }
            let indexBlob = stagedBlob(file: newFile)
            let headBlob = fileBlob(head: head, path: oldFile)

            return .diff(PatchMaker(
                repository: self,
                from: PatchMaker.SourceType(headBlob),
                to: PatchMaker.SourceType(indexBlob),
                path: newFile)
            )
        } else if let newFile {
            guard isTextFile(newFile, context: .workspace)
            else { return .binary }
            let indexBlob = stagedBlob(file: newFile)
            let headBlob = fileBlob(head: head, path: newFile)

            return .diff(PatchMaker(
                repository: self,
                from: PatchMaker.SourceType(headBlob),
                to: PatchMaker.SourceType(indexBlob),
                path: newFile)
            )
        } else if let oldFile {
            guard isTextFile(oldFile, context: .workspace)
            else { return .binary }
            let indexBlob = stagedBlob(file: oldFile)
            let headBlob = fileBlob(head: head, path: oldFile)

            return .diff(PatchMaker(
                repository: self,
                from: PatchMaker.SourceType(headBlob),
                to: PatchMaker.SourceType(indexBlob),
                path: oldFile)
            )
        } else {
            return nil
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

    #warning("handle rename by passing old path as well as new path")
    /// Returns a diff maker for a file in the workspace, compared to the index.
    func unstagedDiff(oldFile: String?, newFile: String?) -> PatchMaker.PatchResult?
    {
        guard (oldFile != nil || newFile != nil) else { return nil }
        if let file = oldFile ?? newFile {
        }

        if let oldFile, let newFile {
            guard isTextFile(oldFile, context: .workspace), isTextFile(newFile, context: .workspace)
            else { return .binary }
            let oldFileURL = fileURL(oldFile)
            let oldFileExists = FileManager.fileExists(at: oldFileURL.path)
            let newFileURL = fileURL(newFile)
            let newFileExists = FileManager.fileExists(at: newFileURL.path)

            do {
                let oldFileData = oldFileExists ? try Data(contentsOf: oldFileURL) : Data()
                let newFileData = newFileExists ? try Data(contentsOf: newFileURL) : Data()
                if let stagedBlob = stagedBlob(file: oldFile) {
                    return .diff(PatchMaker(
                        repository: self,
                        from: PatchMaker.SourceType(stagedBlob),
                        to: .data(newFileData),
                        path: newFile)
                    )
                }
                else {
                    return .diff(PatchMaker(
                        repository: self,
                        from: .data(oldFileData),
                        to: .data(newFileData),
                        path: newFile)
                    )
                }
            }
            catch {
                return nil
            }
        } else if let newFile {
            guard isTextFile(newFile, context: .workspace)
            else { return .binary }
            let url = fileURL(newFile)
            let exists = FileManager.fileExists(at: url.path)

            do {
                let data = exists ? try Data(contentsOf: url) : Data()
                if let stagedBlob = stagedBlob(file: newFile) {
                    return .diff(PatchMaker(
                        repository: self,
                        from: PatchMaker.SourceType(stagedBlob),
                        to: .data(data),
                        path: newFile)
                    )
                }
                else {
                    return .diff(PatchMaker(
                        repository: self,
                        from: .data(Data()),
                        to: .data(data),
                        path: newFile)
                    )
                }
            }
            catch {
                return nil
            }
        } else if let oldFile {
            guard isTextFile(oldFile, context: .workspace)
            else { return .binary }
            let url = fileURL(oldFile)
            if let stagedBlob = stagedBlob(file: oldFile) {
                return .diff(PatchMaker(
                    repository: self,
                    from: PatchMaker.SourceType(stagedBlob),
                    to: .data(Data()),
                    path: oldFile)
                )
            }
            else {
                return .diff(PatchMaker(
                    repository: self,
                    from: .data(Data()),
                    to: .data(Data()),
                    path: oldFile)
                )
            }
        } else {
            return nil
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
