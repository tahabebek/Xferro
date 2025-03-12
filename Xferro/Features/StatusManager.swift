//
//  StatusManager.swift
//  Xferro
//
//  Created by Taha Bebek on 2/15/25.
//

import Foundation

final class StatusManager {
    static let shared = StatusManager()
    let lock = NSRecursiveLock()

    private init() {}

#warning("Check if you can use lsFiles for status view")
    //        let lsFiles = GitCLI.executeGit(self, ["ls-files", "--stage", filePath])
    //        print("ls-files: \(lsFiles)")
    func status(of repository: Repository) async -> [StatusEntry] {
        repository.status(options: [
            .includeUntracked,
            .renamesFromRewrites,
            .renamesHeadToIndex,
            .renamesIndexToWorkdir,
            .sortCaseSensitively,
            .updateIndex
        ]).mustSucceed(repository.gitDir)
    }

    func isUntracked(relativePath: String, statusEntries: [StatusEntry]) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        var maybePartiallyUntracked = false
        for statusEntry in statusEntries {
            for delta in statusEntry.deltas {
                switch delta.status {
                case .untracked:
                    if let filePath = delta.newFilePath, relativePath == filePath {
                        maybePartiallyUntracked = true
                    }
                    if let filePath = delta.oldFilePath, relativePath == filePath {
                        maybePartiallyUntracked = true
                    }
                default:
                    if let filePath = delta.newFilePath, relativePath == filePath {
                        return false
                    }
                    if let filePath = delta.oldFilePath, relativePath == filePath {
                        return false
                    }
                }
            }
        }
        return maybePartiallyUntracked
    }

    func isStagedOrUnstaged(relativePath: String, statusEntries: [StatusEntry]) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        for statusEntry in statusEntries {
            for delta in statusEntry.deltas {
                switch delta.status {
                case .untracked:
                    break
                default:
                    if let filePath = delta.newFilePath, relativePath == filePath {
                        return true
                    }
                    if let filePath = delta.oldFilePath, relativePath == filePath {
                        return true
                    }
                }
            }
        }
        return false
    }

    func untrackedPaths(in status: [StatusEntry]) -> Set<URL> {
        var fileURLs = Set<URL>()
        status
            .forEach {
                if let delta = $0.unstagedDelta {
                    switch delta.status {
                    case .untracked:
                        if let oldFileURL = delta.oldFileURL {
                            fileURLs.insert(oldFileURL)
                        }
                        if let newFileURL = delta.newFileURL {
                            fileURLs.insert(newFileURL)
                        }
                    default:
                        break
                    }
                }
            }
        return fileURLs
    }

    func trackedFiles(in status: [StatusEntry]) -> Set<URL> {
        var fileURLs = Set<URL>()
        status
            .forEach {
                if let delta = $0.unstagedDelta {
                    switch delta.status {
                    case .untracked:
                        break
                    default:
                        if let oldFileURL = delta.oldFileURL {
                            fileURLs.insert(oldFileURL)
                        }
                        if let newFileURL = delta.newFileURL {
                            fileURLs.insert(newFileURL)
                        }
                    }
                }
            }
        return fileURLs
    }
}
