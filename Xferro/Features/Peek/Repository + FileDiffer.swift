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

        var toSource: PatchMaker.SourceType = if let toBlob = blob(commit: toCommit, file: file) {
            .blob(toBlob)
        } else {
            .data(Data())
        }

        var fromSource: PatchMaker.SourceType =
        if let parentCommit, let fromBlob = blob(commit: parentCommit, file: file) {
            .blob(fromBlob)
        } else {
            .data(Data())
        }

        return .diff(PatchMaker(repository: self, from: fromSource, to: toSource, path: file))
    }

    /// Returns a diff maker for a file in the index, compared to HEAD
    func stagedDiff(head: Head, file: String) -> PatchMaker.PatchResult?
    {
        guard isTextFile(file, context: .index)
        else { return .binary }

        let indexBlob = stagedBlob(file: file)
        let headBlob = fileBlob(head: head, path: file)

        return .diff(PatchMaker(
            repository: self,
            from: PatchMaker.SourceType(headBlob),
            to: PatchMaker.SourceType(indexBlob),
            path: file)
        )
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
    func unstagedDiff(file: String) -> PatchMaker.PatchResult?
    {
        guard isTextFile(file, context: .workspace)
        else { return .binary }

        let url = fileURL(file)
        let exists = FileManager.default.fileExists(atPath: url.path)

        do {
            let data = exists ? try Data(contentsOf: url) : Data()
            if let stagedBlob = stagedBlob(file: file) {
                return .diff(PatchMaker(
                    repository: self,
                    from: PatchMaker.SourceType(stagedBlob),
                    to: .data(data),
                    path: file)
                )
            }
            else {
                return .diff(PatchMaker(
                    repository: self,
                    from: .data(Data()),
                    to: .data(data),
                    path: file)
                )
            }
        }
        catch {
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
        let tree = tree(commit.tree.oid).mustSucceed()
        guard let toEntry = tree.entries[path] else { return nil }

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
            if let blob = blob(commit: commit, file: path) {
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

    func blob(commit: Commit, file: String) -> Blob? {
        let tree = tree(commit.tree.oid).mustSucceed()
        guard let toEntry = tree.entries[file] else { return nil }

        if case .blob(let oid) = toEntry.object {
            return withGitObject(oid, type: GIT_OBJECT_BLOB) {
                Blob($0, lock: lock)
            }.mustSucceed()
        }
        return nil
    }
}
