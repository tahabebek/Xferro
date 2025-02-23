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

    func status(of repository: Repository) -> [StatusEntry] {
        lock.lock()
        defer { lock.unlock() }
        return repository.status(options: [
            .includeUntracked,
            .renamesFromRewrites,
            .renamesHeadToIndex,
            .renamesIndexToWorkdir,
            .sortCaseSensitively,
            .updateIndex
        ]).mustSucceed()
        #warning("Fix locked repo crashes ( rm /Users/tahabebek/Projects/Xferro/.git/index.lock fixes it)")
    }

    func isUntracked(relativePath: String, statusEntries: [StatusEntry]) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        for statusEntry in statusEntries {
            if let delta = statusEntry.unstagedDelta {
                if case .untracked = delta.status,
                   let filePath = delta.newFile?.path,
                   relativePath == filePath {
                    return true
                }
            }
        }
        return false
    }

    func untrackedFiles(in status: [StatusEntry]) -> Set<URL> {
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
