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
        case commit(OpaquePointer)
        case index
        case workspace
    }

    // if a file is in wip but not in owner, it will look like an addition
    func patchMakerFromOwnerToWip(
        oldNewFile: OldNewFile,
        ownerCommit: OpaquePointer,
        wipCommit: OpaquePointer
    ) -> PatchMaker.PatchResult {
        switch oldNewFile.status {
        case .unmodified:
            return .noDifference
        case .untracked:
            fatalError(.unimplemented)
        case .added, .copied:
            guard let newFile = oldNewFile.new else {
                fatalError(.invalid)
            }

            guard isTextFile(newFile, context: .commit(wipCommit)) else { return .binary }

            let toSource: PatchMaker.SourceType = if let toBlob = blob(commit: wipCommit, path: newFile) {
                .blob(toBlob)
            } else {
                .data(Data())
            }

            let fromSource: PatchMaker.SourceType = .data(Data())
            return .diff(PatchMaker(repository: self, from: fromSource, to: toSource, path: newFile))
        case .modified:
            guard let newFile = oldNewFile.new else {
                fatalError(.invalid)
            }

            guard isTextFile(newFile, context: .commit(wipCommit)) ||
                    isTextFile(newFile, context: .commit(ownerCommit))
            else { return .binary }

            let toSource: PatchMaker.SourceType = if let toBlob = blob(commit: wipCommit, path: newFile) {
                .blob(toBlob)
            } else {
                .data(Data())
            }

            let fromSource: PatchMaker.SourceType =
            if let fromBlob = blob(commit: ownerCommit, path: newFile) {
                .blob(fromBlob)
            } else {
                .data(Data())
            }

            return .diff(PatchMaker(repository: self, from: fromSource, to: toSource, path: newFile))
        case .deleted:
            guard let oldFile = oldNewFile.old else {
                fatalError(.invalid)
            }

            guard isTextFile(oldFile, context: .commit(ownerCommit)) else {
                return .binary
            }

            let toSource: PatchMaker.SourceType = .data(Data())

            let fromSource: PatchMaker.SourceType =
            if let fromBlob = blob(commit: ownerCommit, path: oldFile) {
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
            guard isTextFile(newFile, context: .commit(wipCommit)) ||
                    isTextFile(oldFile, context: .commit(ownerCommit))
            else { return .binary }

            let toSource: PatchMaker.SourceType = if let toBlob = blob(commit: wipCommit, path: newFile) {
                .blob(toBlob)
            } else {
                .data(Data())
            }

            let fromSource: PatchMaker.SourceType =
            if let fromBlob = blob(commit: ownerCommit, path: oldFile) {
                .blob(fromBlob)
            } else {
                .data(Data())
            }

            return .diff(PatchMaker(repository: self, from: fromSource, to: toSource, path: newFile))
        case .ignored, .unreadable, .conflicted:
            fatalError(.invalid)
        }
    }

    func patchMakerForAStagedFileComparedToHEAD(head: Head, oldNewFile: OldNewFile) -> PatchMaker.PatchResult {
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
        case .ignored, .unreadable, .conflicted:
            fatalError(.invalid)
        }
    }

    func patchMakerForAStagedFileComparedToHEAD1(head: Head, file: String) -> PatchMaker.PatchResult? {
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

    func patchMakerForAFileInTeWorkspaceComparedToHead(head: Head, oldNewFile: OldNewFile) -> PatchMaker.PatchResult {
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
            let newFileData = try! Data(contentsOf: workDir.appendingPathComponent(newFile))
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
        case .modified, .conflicted:
            guard let newFile = oldNewFile.new else {
                fatalError(.invalid)
            }
            guard isTextFile(newFile, context: .workspace) else {
                return .binary
            }
            guard let newFileData = try? Data(contentsOf: workDir.appendingPathComponent(newFile)) else {
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
            let newFileData = try! Data(contentsOf: workDir.appendingPathComponent(newFile))
            let headBlob = fileBlob(head: head, path: oldFile)
            return .diff(PatchMaker(
                repository: self,
                from: PatchMaker.SourceType(headBlob),
                to: .data(newFileData),
                path: newFile)
            )
        case .ignored, .unreadable:
            fatalError(.invalid)
        }
    }

    func blame(for path: String, from startOID: OID?, to endOID: OID?) -> Blame? {
        Blame(repository: self, path: path, from: startOID, to: endOID)
    }

    func blame(for path: String, data fromData: Data?, to endOID: OID?) -> Blame? {
        Blame(repository: self, path: path, data: fromData ?? Data(), to: endOID)
    }

    func stagedBlob(file: String) -> Blob? {
        let index = index().mustSucceed(gitDir)
        guard let entryOID = index.entry(at: file)?.oid else { return nil }
        return withGitObject(entryOID, type: GIT_OBJECT_BLOB) {
            Blob($0, lock: lock)
        }.mustSucceed(gitDir)
    }

    func fileBlob(head: Head, path: String) -> Blob? {
        commitBlob(commit: head.commit, path: path)
    }

    func commitBlob(commit: Commit, path: String) -> Blob? {
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
            return try? withGitObject(oid, type: GIT_OBJECT_BLOB) {
                Blob($0, lock: lock)
            }.get()
        }
        return nil
    }

    /// Returns true if the file seems to be text, based on its name or its content.
    /// - parameter path: File path relative to the repository
    /// - parameter context: Where to look for the specified file
    func isTextFile(_ path: String, context: FileContext) -> Bool {
        let name = (path as NSString).lastPathComponent
        guard !name.isEmpty
        else { return false }

        if Self.textNames.contains(name) {
            return true
        }
        if Self.isTextExtension(name) {
            return true
        }
        
        var tempFilePath: String?
        do {
            var url = fileURL(path)
            if !FileManager.fileExists(url.path) {
                let headFileLines = try GitCLI.showHead(self, path).get().lines
                tempFilePath = DataManager.appDirPath + "/" + UUID().uuidString
                try headFileLines.joined(separator: "\n").write(toFile: tempFilePath!, atomically: true, encoding: .utf8)
                url = URL(fileURLWithPath: tempFilePath!)
            }
            
            
            let fileHandle = try FileHandle(forReadingFrom: url)
            defer { fileHandle.closeFile() }
            
            defer {
                if tempFilePath != nil {
                    try? FileManager.default.removeItem(at: url)
                }
            }
            // Read only a small sample (first 1024 bytes is usually sufficient)
            let sampleData = fileHandle.readData(ofLength: 1024)
            
            // Check for null bytes (common in binary files)
            if sampleData.contains(0) {
                return false
            }
            
            // Try to decode as UTF-8 without converting the entire file
            // We only need to know if the sample can be decoded, not the actual string content
            if String(data: sampleData, encoding: .utf8) != nil {
                return true
            }
            
            // Optional: Check for other text encodings if UTF-8 fails
            for encoding in [String.Encoding.ascii, .utf16, .isoLatin1, .isoLatin2] {
                if String(data: sampleData, encoding: encoding) != nil {
                    return true
                }
            }
            
        } catch {
            if tempFilePath != nil {
                try? FileManager.default.removeItem(at: URL(fileURLWithPath: tempFilePath!))
            }
            print("Error examining file: \(error)")
        }

        switch context {
        case .commit(let commit):
            if let blob = blob(commit: commit, path: path) {
                return !blob.isBinary
            }
        case .index:
            let index = index().mustSucceed(gitDir)
            guard let entryOID = index.entry(at: path)?.oid else { return false }
            let blob = withGitObject(entryOID, type: GIT_OBJECT_BLOB) {
                Blob($0, lock: lock)
            }.mustSucceed(gitDir)
            return !blob.isBinary
        case .workspace:
            let url = self.fileURL(path)
            guard let data = try? Data(contentsOf: url)
            else { return false }

            return !data.isBinary()
        }

        return false
    }

    static func isTextExtension(_ name: String) -> Bool {
        let ext = (name as NSString).pathExtension
        guard !ext.isEmpty, let type = UTType(filenameExtension: ext) else {
            return false
        }

        return type.conforms(to: .text)
    }

    func fileURL(_ file: String) -> URL {
        return workDir.appendingPathComponent(file)
    }

    func blob(commit: OpaquePointer, path: String) -> Blob? {
        var treePointer: OpaquePointer? = nil
        let treeResult = git_commit_tree(&treePointer, commit)

        guard treeResult == GIT_OK.rawValue, let treePointer else {
            let err = NSError(gitError: treeResult, pointOfFailure: "git_commit_tree")
            fatalError(err.localizedDescription)
        }
        guard let toEntry = Tree.entry(tree: treePointer, path: path) else {
            let err = NSError(gitError: treeResult, pointOfFailure: "Tree.entry")
            fatalError(err.localizedDescription)
        }

        if case .blob(let oid) = toEntry.object {
            return withGitObject(oid, type: GIT_OBJECT_BLOB) {
                Blob($0, lock: lock)
            }.mustSucceed(gitDir)
        }
        return nil
    }
}
