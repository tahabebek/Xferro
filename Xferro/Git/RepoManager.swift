//
//  RepoManager.swift
//  Xferro
//
//  Created by Taha Bebek on 1/14/25.
//

import Foundation

struct RepoManager {
    func cleanGarbage(_ repository: Repository) {
        guard let workDir = repository.workDir else {
            return
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["gc", "--prune=now"]
        process.currentDirectoryURL = URL(fileURLWithPath: workDir.path)

        // To capture output if needed
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try? process.run()
        process.waitUntilExit()

        // Check if successful
        if process.terminationStatus != 0 {
            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let error = NSError(domain: "GitError",
                          code: Int(process.terminationStatus),
                          userInfo: [NSLocalizedDescriptionKey: "Git GC failed: \(output)"])
            print(error)
        }
    }

    func printFolderTree(_ repository: Repository) {
        guard let workDir = repository.workDir else {
            return
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/tree")
        process.arguments = ["-a"]
        process.currentDirectoryURL = URL(fileURLWithPath: workDir.path)

        // To capture output if needed
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try? process.run()

        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: outputData, encoding: .utf8) {
            print(output)
        }
        
        process.waitUntilExit()

        // Check if successful
        if process.terminationStatus != 0 {
            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let error = NSError(domain: "GitError",
                                code: Int(process.terminationStatus),
                                userInfo: [NSLocalizedDescriptionKey: "Tree failed: \(output)"])
            print(error)
        }
    }

    func git(_ repository: Repository, _ args: [String]) -> String {
        guard let workDir = repository.workDir else {
            fatalError("no work dir")
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")

        var environment = [String: String]()
        environment["PATH"] = "/usr/bin:/bin:/usr/sbin:/sbin"
        environment["HOME"] = NSHomeDirectory()
        environment["GIT_CONFIG_NOSYSTEM"] = "1"
        environment["GIT_TERMINAL_PROMPT"] = "0"
        environment["GIT_EXEC_PATH"] = "/usr/libexec/git-core"
        environment["GIT_TEMPLATE_DIR"] = "/usr/share/git-core/templates"
        // Disable all external commands/helpers
        environment["GIT_EXTERNAL_DIFF"] = "true"
        environment["GIT_PAGER"] = "cat"
        process.environment = environment

        var fullArgs = [
            "-c", "user.name=Temporary",
            "-c", "user.email=temporary@example.com",
            "-c", "core.autocrlf=false",
            "-c", "core.editor=true",
            "-c", "filter.lfs.clean=true",
            "-c", "filter.lfs.smudge=true",
            "-c", "filter.lfs.process=true",
            "-c", "filter.lfs.required=false"
        ]
        fullArgs.append(contentsOf: args)
        process.arguments = fullArgs
        process.currentDirectoryURL = URL(fileURLWithPath: workDir.path)

        // To capture output if needed
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            if process.terminationStatus != 0 {
                print("Git command failed with status \(process.terminationStatus)")
                print("Command output: \(output)")
                let error = NSError(domain: "GitError",
                                    code: Int(process.terminationStatus),
                                    userInfo: [NSLocalizedDescriptionKey: "Git failed: \(output)"])
                print(error)
            }
            return output
        } catch {
            print("Failed to run git: \(error)")
            return ""
        }
    }

    func printBranchTree(repository: Repository) {
        
    }

    func dumpRepo(_ repository: Repository) {
        guard case .success(let branches) = repository.localBranches() else {
            fatalError("Failed to get local branches")
        }

        guard case .success(let head) = repository.HEAD() else {
            fatalError( "Failed to get head commit")
        }
        print("----------------------------------------------")
        if head.longName.isBranchRef {
            print("Current branch: \(head.longName)")
            printBranch(repository: repository, branch: head as! Branch)
        } else if head.longName.isTagRef {
            print("Current tag: \(head.longName)")
            printTag(repository: repository, tag: head as! TagReference)
        } else {
            print("Current detached head commit: \(head.oid)")
            guard case .success(let commit) = repository.commit(head.oid) else {
                fatalError( "Failed to get head commit")
            }
            dumpCommitAndTree(commit: commit, repository: repository)
        }

        for branch in branches {
            if branch.longName == head.longName {
                continue
            }
            print("----------------------------------------------")
            print("Branch: \(branch.longName), commit: \(branch.commit.oid)")
            printBranch(repository: repository, branch: branch)
        }
        printIndexContents(repository)
    }

    private func printBranch(repository: Repository, branch: Branch) {
        let commitIterator = repository.commits(in: branch, reversed: true)
        for commitResult in commitIterator {
            guard case .success(let commit) = commitResult else {
                fatalError("Failed to get commit")
            }
            dumpCommitAndTree(commit: commit, repository: repository)
        }
    }

    private func printTag(repository: Repository, tag: TagReference) {
        let commitIterator = repository.commits(in: tag)
        for commitResult in commitIterator {
            guard case .success(let commit) = commitResult else {
                fatalError("Failed to get commit")
            }
            dumpCommitAndTree(commit: commit, repository: repository)
        }
    }

    private func dumpCommitAndTree(commit: Commit, repository: Repository, level: Int = 0) {
        let prefix = String(repeating: "\t", count: level)
        print("\n", prefix, commit)
        guard case .success(let tree) = repository.tree(commit.tree.oid) else {
            fatalError("Could not get tree for commit \(commit.oid)")
        }
        dumpTree(tree, repository: repository, level: level + 1)
    }

    private func dumpTree(_ tree: Tree, repository: Repository, level: Int = 0) {
        let prefix = String(repeating: "\t", count: level)
        print(prefix, "Tree entries: \(tree.entries.count)")
        for key in tree.entries.keys {
            let entry = tree.entries[key]!
            let type = entry.object.type
            switch type {
            case .any, .invalid, .offsetDelta, .refDelta:
                fatalError("unexpected object type \(type)")
            case .commit:
                print(prefix, entry.object)
            case .tree:
                print(prefix, entry.object)
                guard case .success(let tree) = repository.tree(entry.object.oid) else {
                    fatalError("Could not get tree for oid \(entry.object.oid)")
                }
                dumpTree(tree, repository: repository, level: level + 1)
            case .blob:
                print(prefix, entry.object)
            case .tag:
                print(prefix, entry.object)
            }
        }
    }

    private func printIndexContents(_ repository: Repository) {
        print("----------------------------------------------")
        guard case .success(let status) = repository.status(options: [.includeUntracked]) else {
            fatalError("Could not get status")
        }
        print(status)
    }
}
