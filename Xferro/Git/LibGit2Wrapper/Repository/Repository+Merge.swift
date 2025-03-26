//
//  Repository+MergeBase.swift
//  SwiftGit2-OSX
//
//  Created by Whirlwind on 2019/6/20.
//  Copyright © 2019 GitHub, Inc. All rights reserved.
//

import Foundation

struct GitMergeAnalysisStatus: OptionSet, CustomDebugStringConvertible {
    let rawValue: UInt32

    /**
     * A "normal" merge; both HEAD and the given merge input have diverged
     * from their common ancestor.  The divergent commits must be merged.
     */
    static let normal = GitMergeAnalysisStatus(rawValue: 1 << 0)
    /**
     * All given merge inputs are reachable from HEAD, meaning the
     * repository is up-to-date and no merge needs to be performed.
     */
    static let upToDate = GitMergeAnalysisStatus(rawValue: 1 << 1)
    /**
     * The given merge input is a fast-forward from HEAD and no merge
     * needs to be performed.  Instead, the client can check out the
     * given merge input.
     */
    static let fastForward = GitMergeAnalysisStatus(rawValue: 1 << 2)
    /**
     * The HEAD of the current repository is "unborn" and does not point to
     * a valid commit.  No merge can be performed, but the caller may wish
     * to simply set HEAD to the target commit(s).
     */
    static let unborn = GitMergeAnalysisStatus(rawValue: 1 << 3)

    init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    var debugDescription: String {
        var components: [String] = []

        if self.contains(.normal) {
            components.append("normal")
        }
        if self.contains(.upToDate) {
            components.append("upToDate")
        }
        if self.contains(.fastForward) {
            components.append("fastForward")
        }
        if self.contains(.unborn) {
            components.append("unborn")
        }

        if components.isEmpty {
            return "GitMergeAnalysisStatus(none)"
        } else {
            return "GitMergeAnalysisStatus(\(components.joined(separator: ", ")))"
        }
    }
}

enum MergeConflictStrategy {
    case failOnConflict
    case acceptTheirs
}

extension Repository {

    func mergeBase(between oid1: OID, and oid2: OID) -> Result<OID, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var baseOID = git_oid()
        var oid1 = oid1.oid
        var oid2 = oid2.oid
        let result = git_merge_base(&baseOID, self.pointer, &oid1, &oid2)
        guard result == GIT_OK.rawValue else {
            return .failure(NSError(gitError: result, pointOfFailure: "git_merge_base"))
        }
        return .success(OID(baseOID))
    }

    func mergeAnalyze(sourceOID: OID, targetBranch: Branch) -> Result<GitMergeAnalysisStatus, NSError> {
        lock.lock()
        defer { lock.unlock() }
        if sourceOID == targetBranch.oid {
            return .success(.upToDate)
        }

        var annotatedCommit: OpaquePointer?
        defer { git_annotated_commit_free(annotatedCommit) }
        var oid = sourceOID.oid
        var result = git_annotated_commit_lookup(&annotatedCommit, self.pointer, &oid)
        guard result == GIT_OK.rawValue else {
            return .failure(NSError(gitError: result, pointOfFailure: "git_annotated_commit_lookup"))
        }

        let referenceResult = reference(
            longName: targetBranch.longName
        ) { targetRef -> Result<GitMergeAnalysisStatus, NSError> in
            var preference = GIT_MERGE_PREFERENCE_NONE
            var analysisResult: git_merge_analysis_t = GIT_MERGE_ANALYSIS_NONE
            result = git_merge_analysis_for_ref(
                &analysisResult,
                &preference,
                self.pointer,
                targetRef,
                &annotatedCommit,
                1
            )
            guard result == GIT_OK.rawValue else {
                return .failure(NSError(gitError: result, pointOfFailure: "git_merge_analysis_for_ref"))
            }

            return .success(GitMergeAnalysisStatus(rawValue: analysisResult.rawValue))
        }
        switch referenceResult {
        case .success(let success):
            if let success {
                return .success(success)
            } else {
                return .failure(NSError(gitError: result, pointOfFailure: "git_merge_analysis_for_ref"))
            }
        case .failure:
            return .failure(NSError(gitError: result, pointOfFailure: "git_merge_analysis_for_ref"))
        }
    }

    private func merge<T>(with oid: OID, block: (OpaquePointer) -> Result<T, NSError>) -> Result<T, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var result: Int32
        var git_oid = oid.oid

        // Do a merge
        var mergeOptions = git_merge_options()
        result = git_merge_options_init(&mergeOptions, UInt32(GIT_MERGE_OPTIONS_VERSION))
        guard result == GIT_OK.rawValue else {
            return .failure(NSError(gitError: result,
                                    pointOfFailure: "git_merge_init_options"))
        }

        var checkoutOptions = git_checkout_options()
        result = git_checkout_options_init(&checkoutOptions, UInt32(GIT_CHECKOUT_OPTIONS_VERSION))
        guard result == GIT_OK.rawValue else {
            return .failure(NSError(gitError: result,
                                    pointOfFailure: "git_checkout_init_options"))
        }

        checkoutOptions.checkout_strategy = GIT_CHECKOUT_SAFE.rawValue | GIT_CHECKOUT_ALLOW_CONFLICTS.rawValue

        var annotatedCommit: OpaquePointer?
        git_oid = oid.oid
        defer { git_annotated_commit_free(annotatedCommit) }
        result = git_annotated_commit_lookup(&annotatedCommit, self.pointer, &git_oid)
        guard result == GIT_OK.rawValue else {
            return .failure(NSError(gitError: result,
                                    pointOfFailure: "git_annotated_commit_lookup"))
        }

        result = git_merge(self.pointer, &annotatedCommit, 1, &mergeOptions, &checkoutOptions)
        guard result == GIT_OK.rawValue else {
            return .failure(NSError(gitError: result,
                                    pointOfFailure: "git_merge"))
        }

        var index: OpaquePointer?
        defer { git_index_free(index) }
        result = git_repository_index(&index, self.pointer)
        guard result == GIT_OK.rawValue else {
            return .failure(NSError(gitError: result,
                                    pointOfFailure: "git_repository_index"))
        }
        return block(index!)
    }

    func merge(
        with oid: OID,
        message: String,
        conflictStrategy: MergeConflictStrategy = .failOnConflict
    ) -> Result<GitMergeAnalysisStatus, NSError> {
        lock.lock()
        defer { lock.unlock() }
        let head = Head.of(self)
        guard case .branch(let targetBranch, _) = head else {
            return .failure(NSError(gitError: GIT_ERROR.rawValue, pointOfFailure: "Current Head is not a branch."))
        }

        do {
            if oid == targetBranch.oid {
                return .success(.upToDate)
            }

            let status = try mergeAnalyze(sourceOID: oid, targetBranch: targetBranch).get()
            if status.contains(.upToDate) {
                // Nothing to do
                return .success(.upToDate)
            } else if status.contains(.fastForward) || status.contains(.unborn) {
                // Fast-forward branch
                return self.update(reference: targetBranch.longName, to: oid).flatMap({
                    Head.checkout(repository: self, longName: targetBranch.longName, CheckoutOptions(strategy: .Force)).flatMap {
                        .success(.fastForward)
                    }
                })
            } else {
                var result: Int32
                var git_oid = oid.oid

                var sourceCommit: OpaquePointer? = nil
                defer { git_commit_free(sourceCommit) }
                result = git_commit_lookup(&sourceCommit, self.pointer, &git_oid)
                guard result == GIT_OK.rawValue else {
                    return .failure(NSError(gitError: result, pointOfFailure: "git_commit_lookup"))
                }


                var sourceTree: OpaquePointer? = nil
                result = git_commit_tree(&sourceTree, sourceCommit)
                guard result == GIT_OK.rawValue else {
                    return .failure(NSError(gitError: result,
                                            pointOfFailure: "git_commit_tree"))
                }

                var targetCommit: OpaquePointer? = nil
                git_oid = targetBranch.oid.oid
                defer { git_commit_free(targetCommit) }
                result = git_commit_lookup(&targetCommit, self.pointer, &git_oid)
                guard result == GIT_OK.rawValue else {
                    return .failure(NSError(gitError: result, pointOfFailure: "git_commit_lookup"))
                }

                var targetTree: OpaquePointer? = nil
                result = git_commit_tree(&targetTree, targetCommit)
                guard result == GIT_OK.rawValue else {
                    return .failure(NSError(gitError: result,
                                            pointOfFailure: "git_commit_tree"))
                }

                // Do normal merge
                return merge(with: oid) { index in
                    if git_index_has_conflicts(index) != 0 {
                        // Has Conflicts
                        if conflictStrategy == .acceptTheirs {
                            // Resolve conflicts by accepting "theirs"
                            var conflictIterator: OpaquePointer? = nil
                            defer { git_index_conflict_iterator_free(conflictIterator) }

                            result = git_index_conflict_iterator_new(&conflictIterator, index)
                            guard result == GIT_OK.rawValue else {
                                return .failure(NSError(gitError: result, pointOfFailure: "git_index_conflict_iterator_new"))
                            }

                            while true {
                                var ancestor: UnsafePointer<git_index_entry>? = nil
                                var ours: UnsafePointer<git_index_entry>? = nil
                                var theirs: UnsafePointer<git_index_entry>? = nil

                                result = git_index_conflict_next(&ancestor, &ours, &theirs, conflictIterator)
                                if result == GIT_ITEROVER.rawValue {
                                    break // No more conflicts
                                }
                                guard result == GIT_OK.rawValue else {
                                    return .failure(NSError(gitError: result, pointOfFailure: "git_index_conflict_next"))
                                }

                                // Need to get the path, regardless of whether theirs exists
                                let path: String? = {
                                    if let theirs {
                                        return String(cString: theirs.pointee.path)
                                    } else if let ours {
                                        return String(cString: ours.pointee.path)
                                    } else if let ancestor {
                                        return String(cString: ancestor.pointee.path)
                                    }
                                    return nil
                                }()

                                if let path {
                                    if let theirs {
                                        // If theirs exists, add it to the index
                                        result = git_index_add(index, theirs)
                                        guard result == GIT_OK.rawValue else {
                                            return .failure(NSError(gitError: result, pointOfFailure: "git_index_add"))
                                        }
                                    } else {
                                        // If theirs is nil, it means the file was deleted in their branch
                                        // So we should remove it from the index
                                        result = git_index_remove_bypath(index, path)
                                        guard result == GIT_OK.rawValue else {
                                            return .failure(NSError(gitError: result, pointOfFailure: "git_index_remove_bypath"))
                                        }
                                    }

                                    // Remove the conflict marker
                                    result = git_index_conflict_remove(index, path)
                                    guard result == GIT_OK.rawValue else {
                                        return .failure(NSError(gitError: result, pointOfFailure: "git_index_conflict_remove"))
                                    }
                                }
                            }

                            // Write the index back
                            result = git_index_write(index)
                            guard result == GIT_OK.rawValue else {
                                return .failure(NSError(gitError: result, pointOfFailure: "git_index_write"))
                            }
                        } else {
                            // Original behavior - fail on conflict
                            git_error_set_str(Int32(GIT_ERROR_MERGE.rawValue), "There are some conflicts.")
                            return .failure(NSError(gitError: GIT_EMERGECONFLICT.rawValue, pointOfFailure: "git_merge_trees"))
                        }
                    }

                    // do a commit if no conflicts
                    return Signature.default(self).flatMap {
                        $0.makeUnsafeSignature().flatMap {
                            self.commit(index: index,
                                        parentCommits: [targetCommit, sourceCommit],
                                        message: message,
                                        signature: $0).flatMap { _ in
                                            git_repository_state_cleanup(self.pointer)
                                            return .success(.normal)
                            }
                        }
                    }
                }
            }
        } catch {
            return .failure(error as NSError)
        }
    }

    func conflictPaths(index: OpaquePointer) -> Result<[String], NSError> {
        lock.lock()
        defer { lock.unlock() }
        var iterator: OpaquePointer?
        var result = git_index_conflict_iterator_new(&iterator, index)
        defer {
            git_index_conflict_iterator_free(iterator)
        }
        guard result == GIT_OK.rawValue else {
            return .failure(NSError(gitError: result,
                                    pointOfFailure: "git_index_conflict_iterator_new"))
        }
        var paths = [String]()
        var entry: UnsafePointer<git_index_entry>?
        var our: UnsafePointer<git_index_entry>?
        var their: UnsafePointer<git_index_entry>?
        while true {
            result = git_index_conflict_next(&entry, &our, &their, iterator!)
            if result == GIT_ITEROVER.rawValue { break }
            guard result == GIT_OK.rawValue else {
                return .failure(NSError(gitError: result,
                                        pointOfFailure: "git_index_conflict_next"))
            }
            paths.append(String(cString: entry!.pointee.path))
        }
        return .success(paths)
    }

    func hasMergeConflict(with oid: OID) -> Result<Bool, NSError> {
        lock.lock()
        defer { lock.unlock() }
        let stashResult = save(stash: "Check Merge Conflict", keepIndex: true, includeUntracked: true)
        var stashId: Int = -1
        switch stashResult {
        case .success(let stash):
            stashId = stash.id
        case .failure(let error):
            if error.code != GIT_ENOTFOUND.rawValue {
                return .failure(error)
            }
        }
        return merge(with: oid) { index in
            let status = git_index_has_conflicts(index) != 0
            git_repository_state_cleanup(self.pointer)
            _ = self.reset(type: .hard)
            if stashId >= 0 {
                _ = self.pop(stash: stashId)
            }
            return .success(status)
        }
    }

    func getConflictDiffHunks(repoPath: String) throws -> [String: [UnsafePointer<git_diff_hunk>]] {
        var index: OpaquePointer? = nil
        guard git_repository_index(&index, pointer) == 0,
              let idx = index else {
            throw RepoError.unexpected("Unable to get index")
        }
        defer { git_index_free(index) }

        var conflictHunks: [String: [UnsafePointer<git_diff_hunk>]] = [:]

        var conflictIterator: OpaquePointer? = nil
        defer { git_index_conflict_iterator_free(conflictIterator) }

        var result = git_index_conflict_iterator_new(&conflictIterator, index)
        guard result == GIT_OK.rawValue else {
            throw NSError(gitError: result, pointOfFailure: "git_index_conflict_iterator_new")
        }

        var ancestor: UnsafePointer<git_index_entry>? = nil
        var ours: UnsafePointer<git_index_entry>? = nil
        var theirs: UnsafePointer<git_index_entry>? = nil

        while git_index_conflict_next(&ancestor, &ours, &theirs, conflictIterator) == 0 {
            let path: String? = {
                if let theirs {
                    return String(cString: theirs.pointee.path)
                } else if let ours {
                    return String(cString: ours.pointee.path)
                } else if let ancestor {
                    return String(cString: ancestor.pointee.path)
                }
                return nil
            }()

            guard let path else {
                continue
            }

            // Get diff hunks for this conflicted file
            if let hunks = try getDiffHunksForConflict(
                path: path,
                ancestor: ancestor,
                ours: ours,
                theirs: theirs
            ) {
                conflictHunks[path] = hunks
            }
        }

        return conflictHunks
    }

    func getDiffHunksForConflict(
        path: String,
        ancestor: UnsafePointer<git_index_entry>?,
        ours: UnsafePointer<git_index_entry>?,
        theirs: UnsafePointer<git_index_entry>?
    ) throws -> [UnsafePointer<git_diff_hunk>]? {
        var hunks: [UnsafePointer<git_diff_hunk>] = []

        let ancestorBlob = try getBlob(entry: ancestor?.pointee)
        defer { if ancestorBlob != nil { git_blob_free(ancestorBlob) } }

        let ourBlob = try getBlob(entry: ours?.pointee)
        defer { if ourBlob != nil { git_blob_free(ourBlob) } }

        let theirBlob = try getBlob(entry: theirs?.pointee)
        defer { if theirBlob != nil { git_blob_free(theirBlob) } }

        // Create diffs between versions
        // 1. Ancestor to ours
        var diffOurs: OpaquePointer? = nil
        if let ancestorBlob, let ourBlob {
            let result = createDiffBetweenBlobs(
                oldBlob: ancestorBlob,
                newBlob: ourBlob,
                path: path,
                diff: &diffOurs
            )
            if result != 0 {
                throw RepoError.unexpected("Failed to create diff between blobs")
            }
        }
        defer { if diffOurs != nil { git_diff_free(diffOurs) } }

        // 2. Ancestor to theirs
        var diffTheirs: OpaquePointer? = nil
        if let ancestorBlob = ancestorBlob, let theirBlob = theirBlob {
            let result = createDiffBetweenBlobs(
                oldBlob: ancestorBlob,
                newBlob: theirBlob,
                path: path,
                diff: &diffTheirs
            )
            if result != 0 {
                throw RepoError.unexpected("Failed to create diff between blobs")
            }
        }
        defer { if diffTheirs != nil { git_diff_free(diffTheirs) } }

        // 3. Ours to theirs (direct comparison between branches)
        var diffOursToTheirs: OpaquePointer? = nil
        if let ourBlob = ourBlob, let theirBlob = theirBlob {
            let result = createDiffBetweenBlobs(
                oldBlob: ourBlob,
                newBlob: theirBlob,
                path: path,
                diff: &diffOursToTheirs
            )
            if result != 0 {
                throw RepoError.unexpected("Failed to create diff between blobs")
            }
        }
        defer { if diffOursToTheirs != nil { git_diff_free(diffOursToTheirs) } }

        if let diffOurs {
            hunks.append(contentsOf: try collectHunks(from: diffOurs, hunkType: .ancestorToOurs))
        }

        if let diffTheirs {
            hunks.append(contentsOf: try collectHunks(from: diffTheirs, hunkType: .ancestorToTheirs))
        }

        if let diffOursToTheirs{
            hunks.append(contentsOf: try collectHunks(from: diffOursToTheirs, hunkType: .oursToTheirs))
        }

        return hunks
    }

    func getBlob(entry: git_index_entry?) throws -> OpaquePointer? {
        guard let entry else { return nil }

        var blob: OpaquePointer? = nil
        var oid = entry.id
        let result = git_blob_lookup(&blob, pointer, &oid)

        if result != 0 {
            throw RepoError.unexpected("Failed to get blob for index entry")
        }

        return blob
    }

    func collectHunks(
        from diff: OpaquePointer,
        hunkType: DiffHunk.HunkType
    ) throws -> [UnsafePointer<git_diff_hunk>] {
        let contextPtr = UnsafeMutablePointer<HunkContainer>.allocate(capacity: 1)
        contextPtr.initialize(to: HunkContainer(hunkType: hunkType))
        defer { contextPtr.deallocate() }

        let result = git_diff_foreach(diff, nil, nil, hunkCallback, nil, contextPtr)
        if result != 0 {
            throw RepoError.unexpected("Failed to collect hunks from diff")
        }

        return contextPtr.pointee.hunks
    }

    func createDiffBetweenBlobs(
        oldBlob: OpaquePointer?,
        newBlob: OpaquePointer?,
        path: String,
        diff: inout OpaquePointer?
    ) -> Int32 {
        var options = git_diff_options()
        git_diff_options_init(&options, UInt32(GIT_DIFF_OPTIONS_VERSION))

        options.context_lines = 3
        options.flags = GIT_DIFF_INCLUDE_UNMODIFIED.rawValue | GIT_DIFF_FIND_RENAMES.rawValue | GIT_DIFF_FIND_COPIES.rawValue

        return git_diff_blobs(oldBlob, path, newBlob, path, &options, nil, nil, nil, nil, &diff)
    }
}

func hunkCallback(
    _ delta: UnsafePointer<git_diff_delta>?,
    _ hunk: UnsafePointer<git_diff_hunk>?,
    _ payload: UnsafeMutableRawPointer?
) -> Int32 {
    guard let payload, let hunk else { return 0 }
    let container = payload.bindMemory(to: HunkContainer.self, capacity: 1)
    container.pointee.hunks.append(hunk)
    return 0
}

// Context struct for the callback
struct HunkContainer {
    var hunks: [UnsafePointer<git_diff_hunk>] = []
    var hunkType: DiffHunk.HunkType

    init(hunkType: DiffHunk.HunkType) {
        self.hunkType = hunkType
    }
    }
