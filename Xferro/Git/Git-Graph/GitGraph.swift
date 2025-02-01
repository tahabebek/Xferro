//
//  GitGraph.swift
//  Xferro
//
//  Created by Taha Bebek on 1/29/25.
//

import Foundation

let ORIGIN = "origin/"
let FORK = "fork/"

struct GitGraph: Codable {
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
    let head: GGHeadInfo

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
            name = branchRef.name
            isBranch = true
        } else if let tagRef = headRef as? TagReference {
            name = tagRef.name
            isBranch = false
        } else if let reference = headRef as? Reference {
            name = reference.shortName ?? reference.longName
            isBranch = false
        } else {
            fatalError()
        }
        let head = GGHeadInfo(oid: headOid, name: name, isBranch: isBranch)

        var commits: [GGCommitInfo] = []
        var indicesOfCommits: [OID: Int] = [:]
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
                    indicesOfCommits[oid] = idx
                    idx += 1
                }
            }
        }

        Self.assignChildren(commits: &commits, indicesOfCommits: indicesOfCommits)

        var allBranches = try Self.assignBranches(
            repository: repository,
            commits: &commits,
            indicesOfCommits: indicesOfCommits,
            settings: settings
        )

        try Self.correctForkMerges(
            commits: commits,
            indicesOfCommits: indicesOfCommits,
            branches: &allBranches,
            settings: settings
        )

        Self.assignSourcesTargets(
            commits: commits,
            indicesOfCommits: indicesOfCommits,
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
            indicesOfCommits: indicesOfCommits,
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
            indicesOfCommits.map { oid, index in
                (index, filteredIndices[oid])
            },
            uniquingKeysWith: { first, _ in first }
        )

        // Update branch ranges
        for idx in allBranches.indices {
            guard allBranches[safe: idx] != nil else {
                continue
            }
            if var startIdx = allBranches[idx].verticalSpan.start {
                var idx0 = indexMap[startIdx]

                while idx0 == nil {
                    startIdx += 1
                    idx0 = indexMap[startIdx]
                }

                allBranches[idx].verticalSpan.start = idx0.flatMap { $0 }
            }

            if var endIdx = allBranches[idx].verticalSpan.end {
                var idx0 = indexMap[endIdx]

                while idx0 == nil {
                    endIdx -= 1
                    idx0 = indexMap[endIdx]
                }

                allBranches[idx].verticalSpan.end = idx0.flatMap { $0 }
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
        self.commits = filteredCommits
        self.indices = filteredIndices
        self.allBranches = allBranches
        self.branches = branches
        self.tags = tags
        self.head = head
    }
}
