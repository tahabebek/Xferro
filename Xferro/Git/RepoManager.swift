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
    
    func dumpRepo(_ repository: Repository) {
        let repo = repository.pointer
        // Create revision walker
        var walker: OpaquePointer? = nil
        guard git_revwalk_new(&walker, repo) == GIT_OK.rawValue else {
            git_repository_free(repo)
            return
        }

        // Configure for topological sorting
        git_revwalk_sorting(walker, GIT_SORT_TOPOLOGICAL.rawValue)
        git_revwalk_sorting(walker, GIT_SORT_TIME.rawValue)
        // Get all refs
        var iterator: UnsafeMutablePointer<git_reference_iterator>? = nil
        guard git_reference_iterator_new(&iterator, repo) == GIT_OK.rawValue else {
            git_revwalk_free(walker)
            git_repository_free(repo)
            return
        }

        // Push all refs to walker
        while true {
            var ref: OpaquePointer? = nil
            let result = git_reference_next(&ref, iterator)
            if result != GIT_OK.rawValue { break }

            if git_reference_type(ref) == GIT_REFERENCE_DIRECT {
                git_revwalk_push(walker, git_reference_target(ref))
            }
            git_reference_free(ref)
        }
        git_reference_iterator_free(iterator)

        // Walk through commits
        var oid = git_oid()
        while git_revwalk_next(&oid, walker) == GIT_OK.rawValue {
            dumpCommitAndTree(oid, repo: repo)
        }

        printIndexContents(repository)

        git_revwalk_free(walker)
        git_repository_free(repo)
    }

    func addTreeObjects(_ tree: OpaquePointer?, repo: OpaquePointer?, to objects: inout Set<String>) {
        let entryCount = git_tree_entrycount(tree)

        for i in 0..<entryCount {
            guard let entry = git_tree_entry_byindex(tree, i) else { continue }

            if let oid = git_tree_entry_id(entry) {
                objects.insert(String(describing: oid.pointee))
            }

            // If entry is a tree, recurse
            if git_tree_entry_type(entry) == GIT_OBJECT_TREE {
                var subTree: OpaquePointer? = nil
                if git_tree_lookup(&subTree, repo, git_tree_entry_id(entry)) == GIT_OK.rawValue {
                    addTreeObjects(subTree, repo: repo, to: &objects)
                    git_tree_free(subTree)
                }
            }
        }
    }

    func dumpCommitAndTree(_ oid: git_oid, repo: OpaquePointer?) {
        var commit: OpaquePointer? = nil
        var mutableOid = oid
        guard git_commit_lookup(&commit, repo, &mutableOid) == GIT_OK.rawValue else { return }

        print("\nCommit: \(mutableOid)")
        print("Message: \(String(cString: git_commit_message(commit)))")

        // Get parent info
        let parentCount = git_commit_parentcount(commit)
        for i in 0..<parentCount {
            let parentOid = git_commit_parent_id(commit, i)
            print("Parent \(i): \(parentOid?.pointee ?? git_oid())")
        }

        // Get and dump tree
        var tree: OpaquePointer? = nil
        if git_commit_tree(&tree, commit) == GIT_OK.rawValue {
            print("\nTree:")
            dumpTree(tree, repo: repo)
            git_tree_free(tree)
        }

        git_commit_free(commit)
    }

    func dumpTree(_ tree: OpaquePointer?, repo: OpaquePointer?) {
        let entryCount = git_tree_entrycount(tree)
        print("Tree entries: \(entryCount)")

        for i in 0..<entryCount {
            guard let entry = git_tree_entry_byindex(tree, i) else { continue }
            let name = String(cString: git_tree_entry_name(entry))
            let type = git_tree_entry_type(entry)
            let oid = git_tree_entry_id(entry)?.pointee
            let filemode = git_tree_entry_filemode(entry)

            print("  \(name) (\(typeToString(type))) mode=\(filemode.rawValue) -> \(String(describing: oid))")

            // If it's a tree, recurse into it
            if type == GIT_OBJECT_TREE {
                var subtree: OpaquePointer? = nil
                if git_tree_lookup(&subtree, repo, git_tree_entry_id(entry)) == GIT_OK.rawValue {
                    print("    Contents:")
                    dumpTree(subtree, repo: repo)
                    git_tree_free(subtree)
                }
            }
        }
    }

    func dumpObject(_ obj: OpaquePointer?, type: git_object_t, repo: OpaquePointer?) {
        switch type {
        case GIT_OBJECT_COMMIT:
            dumpCommit(obj)
        case GIT_OBJECT_TREE:
            var tree: OpaquePointer? = nil
            if git_tree_lookup(&tree, repo, git_odb_object_id(obj)) == GIT_OK.rawValue {
                dumpTree(tree, repo: repo)
                git_tree_free(tree)
            }
        case GIT_OBJECT_BLOB:
            dumpBlob(obj)
        case GIT_OBJECT_TAG:
            dumpTag(obj)
        default:
            print("  Unknown object type")
        }
    }

    func dumpCommit(_ obj: OpaquePointer?) {
        guard let data = git_odb_object_data(obj) else { return }
        let message = String(cString: data.assumingMemoryBound(to: CChar.self))
        print("  Commit message: \(message)")
    }

    func dumpBlob(_ obj: OpaquePointer?) {
        let size = git_odb_object_size(obj)
        print("  Blob size: \(size) bytes")
        // Optionally print first few bytes of content
        if let data = git_odb_object_data(obj), size > 0 {
            let preview = String(cString: data.assumingMemoryBound(to: CChar.self))
            print("  Preview: \(preview.prefix(100))...")
        }
    }

    func dumpTag(_ obj: OpaquePointer?) {
        guard let data = git_odb_object_data(obj) else { return }
        let message = String(cString: data.assumingMemoryBound(to: CChar.self))
        print("  Tag message: \(message)")
    }

    func typeToString(_ type: git_object_t) -> String {
        switch type {
        case GIT_OBJECT_COMMIT: return "commit"
        case GIT_OBJECT_TREE: return "tree"
        case GIT_OBJECT_BLOB: return "blob"
        case GIT_OBJECT_TAG: return "tag"
        default: return "unknown"
        }
    }

    private func printIndexContents(_ repository: Repository) {
        var index: OpaquePointer?
        guard git_repository_index(&index, repository.pointer) == 0 else {
            fatalError("Failed to get repository index")
        }
        defer { git_index_free(index) }

        let entryCount = git_index_entrycount(index)

        for i in 0..<entryCount {
            guard let entry = git_index_get_byindex(index, i) else {
                continue
            }

            print("File path: \(String(cString: entry.pointee.path))")
            print("File size: \(entry.pointee.file_size)")
            print("Stage: \(git_index_entry_stage(entry))")
        }
    }
}
