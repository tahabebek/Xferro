//
//  GitGraph.swift
//  Xferro
//
//  Created by Taha Bebek on 1/29/25.
//

import Foundation

let ORIGIN = "origin/"
let FORK = "fork/"

/// Represents a git history graph
struct GitGraph {
    let repository: Repository
    let commits: [GGCommitInfo]
    /// Mapping from commit id to index in `commits`
    let indices: [OID: Int]
    /// All detected branches and tags, including merged and deleted
    let allBranches: [GGBranchInfo]
    /// Indices of all real (still existing) branches in `allBranches`
    let branches: [Int]
    /// Indices of all tags in `allBranches`
    let tags: [Int]
    /// The current HEAD
    let head: HeadInfo

    init(
        repository: Repository,
        settings: GGSettings,
        maxCount: Int?
    ) throws {
        var stashes: Set<OID> = []

        try repository.stashes().get().forEach { stash in
            stashes.insert(stash.oid)
        }

        var walk: OpaquePointer?
        git_revwalk_new(&walk, repository.pointer)
        git_revwalk_sorting(walk, GIT_SORT_TOPOLOGICAL.rawValue | GIT_SORT_TIME.rawValue)
        let glob = "*"
        git_revwalk_push_glob(walk, glob.cString(using: .utf8))

        if git_repository_is_shallow(repository.pointer) == 1 {
            throw GGError.shallowCloneNotSupported
        }

        let headRef = try repository.HEAD().get()
        let headOid: OID = headRef.oid
        let name: String
        let isBranch: Bool
        if let branchRef = headRef as? Branch {
            name = branchRef.longName
            isBranch = true
        } else if let tagRef = headRef as? TagReference {
            name = tagRef.longName
            isBranch = false
        } else if let reference = headRef as? Reference {
            name = reference.longName
            isBranch = false
        } else {
            fatalError()
        }
        let head = HeadInfo(oid: headOid, name: name, isBranch: isBranch)

        var commits: [GGCommitInfo] = []
        var indices: [OID: Int] = [:]
        var idx = 0

        while true {
            if let max = maxCount, idx >= max {
                break
            }
            var git_oid = git_oid()
            let revwalkGitResult = git_revwalk_next(&git_oid, walk)
            let nextResult = Next(revwalkGitResult, name: "git_revwalk_next")

            switch nextResult {
            case .error, .over:
                break
            case .okay:
                let oid = OID(git_oid)
                if !stashes.contains(oid),
                   let commit = try? repository.commit(oid).get() {
                    commits.append(GGCommitInfo(commit: commit))
                    indices[oid] = idx
                    idx += 1
                }
            }
        }

        Self.assignChildren(commits: &commits, indices: indices)

        var allBranches = try Self.assignBranches(
            repository: repository,
            commits: &commits,
            indices: indices,
            settings: settings
        )

        try Self.correctForkMerges(
            commits: commits,
            indices: indices,
            branches: &allBranches,
            settings: settings
        )

        Self.assignSourcesTargets(
            commits: commits,
            indices: indices,
            branches: &allBranches
        )

        let (shortestFirst, forward): (Bool, Bool) = {
            switch settings.branchOrder {
            case .shortestFirst(let fwd):
                return (true, fwd)
            case .longestFirst(let fwd):
                return (false, fwd)
            }
        }()

        Self.assignBranchColumns(
            commits: commits,
            indices: indices,
            branches: &allBranches,
            branchSettings: settings.branches,
            shortestFirst: shortestFirst,
            forward: forward
        )

        let filteredCommits = commits.filter { $0.branchTrace != nil }

        let filteredIndices = Dictionary(
            filteredCommits.enumerated().map { (idx, info) in
                (info.oid, idx)
            },
            uniquingKeysWith: { first, _ in first }
        )

        let indexMap = Dictionary(
            indices.map { oid, index in
                (index, filteredIndices[oid])
            },
            uniquingKeysWith: { first, _ in first }
        )

        // Update branch ranges
        for idx in allBranches.indices {
            guard allBranches[safe: idx] != nil else {
                continue
            }
            if var startIdx = allBranches[idx].verticalSpan.0 {
                var idx0 = indexMap[startIdx]

                while idx0 == nil {
                    startIdx += 1
                    idx0 = indexMap[startIdx]
                }

                allBranches[idx].verticalSpan.0 = idx0.flatMap { $0 }
            }

            if var endIdx = allBranches[idx].verticalSpan.1 {
                var idx0 = indexMap[endIdx]

                while idx0 == nil {
                    endIdx -= 1
                    idx0 = indexMap[endIdx]
                }

                allBranches[idx].verticalSpan.1 = idx0.flatMap { $0 }
            }
        }

        let branches = allBranches.enumerated()
            .compactMap { idx, br in
                (!br.isMerged && !br.isTag) ? idx : nil
            }

        let tags = allBranches.enumerated()
            .compactMap { idx, br in
                (!br.isMerged && br.isTag) ? idx : nil
            }
        self.repository = repository
        self.commits = filteredCommits
        self.indices = filteredIndices
        self.allBranches = allBranches
        self.branches = branches
        self.tags = tags
        self.head = head
    }
}
