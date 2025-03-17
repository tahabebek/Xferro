//
//  RepositoryInfo+WorkDirWatcher.swift
//  Xferro
//
//  Created by Taha Bebek on 2/25/25.
//

import Combine
import Foundation

extension RepositoryInfo {
    func setupWorkDirWatcher() -> FileEventStream {
        let untrackedFolders = StatusManager.shared.untrackedPaths(in: self.status)
            .filter {
                $0.isDirectory
            }
            .map { $0.path }

        #warning("add global ignore, and exclude file")
        let gitignoreLines = repository.gitignoreLines()
        let workDirChangeSubject = PassthroughSubject<Set<String>, Never>()

        self.workDirChangeObserver = workDirChangeSubject
            .collect(.byTime(RunLoop.main, .seconds(Self.workDirDebounce)))
            .sink { [weak self] batchPaths in
                guard let self else { return }
                #warning("collect after updating the status, status update is urgent")
                Task { [weak self] in
                    guard let self else { return }
                    self.status = await StatusManager.shared.status(of: repository)
                    let paths = Set(batchPaths
                        .flatMap { batch in
                            batch.map { path in
                                if path.hasSuffix("~") {
                                    String(path.dropLast())
                                } else {
                                    path
                                }
                            }
                        }
                    )
                    if paths.isEmpty {
                        print("rescan workdir")
                        self.workDirWatcher = setupWorkDirWatcher()
                    }
                    var changes: Set<String> = []
                    for path in paths {
                        if repository.ignores(absolutePath: path) {
#warning("check and implement the logic below if necessary")
                            // does the worktree have this file?
                            // yes
                            // Write .gitignore to the worktree
                            // ✅ delete from the worktree

                            continue
                        }
                        if URL(filePath: path).deletingLastPathComponent().path.hasSuffix("~") {
                            continue
                        }


                        let sourceURL = URL(filePath: path)
                        let relativePath = path.droppingPrefix(repository.workDir.path + "/")
                        let destinationPath = wipWorktree.worktreeRepository.workDir.appendingPathComponent(relativePath).path
                        let destinationURL = URL(filePath: destinationPath)
                        let changeFileName = destinationURL.lastPathComponent

                        // is this file in staged or unstaged?
                        if StatusManager.shared.isStagedOrUnstaged(relativePath: relativePath, statusEntries: status) {
                            let isDeleted = !FileManager.fileExists(path)
                            if isDeleted {
                                //                            print("file deleted", relativePath)
                                do {
                                    try FileManager.removeItem(destinationPath)
                                    changes.insert("Wip - \(changeFileName) is deleted")
                                } catch {
                                    print("file deletion failed: \(error.localizedDescription)")
                                }
                            } else {
                                if destinationURL.isDirectory {
                                    try? FileManager.createDirectory(destinationURL.path, withIntermediateDirectories: true)
                                } else {
                                    let contents = try! String(contentsOfFile: path, encoding: .utf8)
                                    let hash = contents.hash
                                    if fileHashes[path] == nil {
                                        fileHashes[path] = hash
                                    } else if fileHashes[path] != hash {
                                        fileHashes[path] = hash
                                    } else {
                                        continue
                                    }
                                    //                                print("file added or modified", relativePath)
                                    try? FileManager.createDirectory(destinationURL.deletingLastPathComponent().path, withIntermediateDirectories: true)
                                    FileManager.createFile(destinationPath, contents: contents.data(using: .utf8))
                                    changes.insert("Wip - \(changeFileName) is modified")
                                }
                            }
                        } else {
                            // is it in untracked?
                            if StatusManager.shared.isUntracked(relativePath: relativePath, statusEntries: status) {
                                // does the worktree have it?
                                if FileManager.fileExists(destinationPath) {
                                    try! FileManager.removeItem(destinationPath)
                                    //                                print("untracked file deleted from worktree", destinationPath)
                                    changes.insert("Wip - \(changeFileName) is removed")
                                } else {
                                    continue
                                }
                            } else {
                                // does the original repo have it?
                                if FileManager.fileExists(path) {
                                    try? FileManager.createDirectory(destinationURL.deletingLastPathComponent().path, withIntermediateDirectories: true)
                                    if !sourceURL.isDirectory {
                                        do {
                                            let contents = try String(contentsOfFile: path, encoding: .utf8)
                                            let hash = contents.hash
                                            if fileHashes[path] == nil {
                                                fileHashes[path] = hash
                                            } else if fileHashes[path] != hash {
                                                fileHashes[path] = hash
                                            } else {
                                                continue
                                            }
                                            FileManager.createFile(destinationPath, contents: contents.data(using: .utf8))
                                        } catch {
                                            continue
                                        }
                                    }
                                    changes.insert("Wip - \(changeFileName) is modified")
                                    //                                print("file (which is not in the index) added or modified", relativePath)
                                } else {
                                    if FileManager.fileExists(destinationPath) {
                                        try! FileManager.removeItem(destinationPath)
                                        changes.insert("Wip - \(changeFileName) is removed")
                                        //                                    print("untracked file deleted from worktree", destinationPath)
                                    }
                                }
                            }
                        }
                    }
                    if changes.isNotEmpty {
                        self.onWorkDirChange?(self, changes.count == 1 ? changes.first! : "Wip - \(changes.count) files are changed")
                    }
                }
            }

        return FileEventStream(
            path: repository.workDir.path,
            excludePaths: [repository.gitDir.path] + untrackedFolders,
            gitignoreLines: gitignoreLines,
            workDir: repository.workDir,
            queue: self.queue.queue,
            changePublisher: workDirChangeSubject)
    }
}
