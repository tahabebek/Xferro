//
//  Repository+Apply.swift
//  Xferro
//
//  Created by Taha Bebek on 3/1/25.
//

import Foundation

extension Repository {
    func discard(delta: Diff.Delta, hunk: DiffHunk)
    {
        var encoding = String.Encoding.utf8
        switch delta.status {
        case .added, .copied:
            guard let url = delta.newFileURL else {
                fatalError(.invalid)
            }
            if FileManager.fileExists(url.path) {
                if url.isDirectory {
                    RepoManager().git(self, ["restore", url.appendingPathComponent("*").path])
                } else {
                    RepoManager().git(self, ["restore", url.path])
                }
                try? FileManager.removeItem(url.path)
                stage(path: delta.newFilePath!).mustSucceed()
            } else {
                fatalError(.invalid)
            }
        case .modified:
            guard let url = delta.newFileURL else {
                fatalError(.invalid)
            }
            do {
                if FileManager.fileExists(url.path) {
                    let fileText = try String(contentsOf: url, usedEncoding: &encoding)
                    guard let result = hunk.applied(to: fileText, reversed: true) else {
                        fatalError(.unknown)
                    }
                    try result.write(to: url, atomically: true, encoding: encoding)
                } else {
                    fatalError(.invalid)
                }
            } catch {
                fatalError(error.localizedDescription)
            }
        case .deleted:
            guard let url = delta.oldFileURL else {
                fatalError(.invalid)
            }
            if !FileManager.fileExists(url.path) {
                if url.isDirectory {
                    RepoManager().git(self, ["restore", url.appendingPathComponent("*").path])
                } else {
                    RepoManager().git(self, ["restore", url.path])
                }
            } else {
                fatalError(.invalid)
            }

        case .renamed:
            break
        case .untracked:
            guard let url = delta.newFileURL else {
                fatalError(.invalid)
            }
            if FileManager.fileExists(url.path) {
                try! FileManager.removeItem(url.path)
            } else {
                fatalError(.invalid)
            }
        case .typeChange:
            guard let oldFileURL = delta.oldFileURL, let newFileURL = delta.newFileURL else {
                fatalError(.invalid)
            }
            do {
                try FileManager.moveItem(oldFileURL, to: newFileURL)
            } catch {
                fatalError(error.localizedDescription)
            }
        case .unreadable, .ignored, .unmodified:
            fatalError(.invalid)
        case .conflicted:
            fatalError(.unimplemented)
        }
    }

    func status(of file: String) throws -> (DeltaStatus, DeltaStatus)
    {
        var statusFlags: UInt32 = 0
        let result = git_status_file(&statusFlags, self.pointer, file)
        guard result == GIT_OK.rawValue else {
            fatalError(.unknown)
        }

        let flags = git_status_t(statusFlags)
        var unstagedChange = DeltaStatus.unmodified
        var stagedChange = DeltaStatus.unmodified

        switch flags {
        case _ where flags.contains(GIT_STATUS_WT_NEW):
            unstagedChange = .untracked
        case _ where flags.contains(GIT_STATUS_WT_MODIFIED),
            _ where flags.contains(GIT_STATUS_WT_TYPECHANGE):
            unstagedChange = .modified
        case _ where flags.contains(GIT_STATUS_WT_DELETED):
            unstagedChange = .deleted
        case _ where flags.contains(GIT_STATUS_WT_RENAMED):
            unstagedChange = .renamed
        case _ where flags.contains(GIT_STATUS_IGNORED):
            unstagedChange = .ignored
        case _ where flags.contains(GIT_STATUS_CONFLICTED):
            unstagedChange = .conflict
            // ignoring GIT_STATUS_WT_UNREADABLE
        default:
            break
        }

        switch flags {
        case _ where flags.contains(GIT_STATUS_INDEX_NEW):
            stagedChange = .added
        case _ where flags.contains(GIT_STATUS_INDEX_MODIFIED),
            _ where flags.contains(GIT_STATUS_WT_TYPECHANGE):
            stagedChange = .modified
        case _ where flags.contains(GIT_STATUS_INDEX_DELETED):
            stagedChange = .deleted
        case _ where flags.contains(GIT_STATUS_INDEX_RENAMED):
            stagedChange = .renamed
        default:
            break
        }

        return (unstagedChange, stagedChange)
    }
}
