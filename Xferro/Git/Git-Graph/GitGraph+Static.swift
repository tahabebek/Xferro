//
//  GitGraph+New.swift
//  Xferro
//
//  Created by Taha Bebek on 1/29/25.
//

import Foundation

extension GitGraph {
    /// Walks through the commits and adds each commit's Oid to the children of its parents.
    static func assignChildren(commits: inout [GGCommitInfo], indicesOfCommits: [OID: Int]) {
        for idx in 0..<commits.count {
            let oid = commits[idx].oid
            let parents = commits[idx].parents

            for parentOid in parents {
                if let parentIdx = indicesOfCommits[parentOid] {
                    commits[parentIdx].children.append(oid)
                    commits[parentIdx].debugchildrenOIDs.append(oid.debugOID)
                }
            }
        }
    }

    /// Extracts branches from repository and merge summaries, assigns branches and branch traces to commits.
    ///
    /// Algorithm:
    /// * Find all actual branches (incl. target oid) and all extract branches from merge summaries (incl. parent oid)
    /// * Sort all branches by persistence
    /// * Iterating over all branches in persistence order, trace back over commit parents until a trace is already assigned
    static func assignBranches(
        repository: Repository,
        commits: inout [GGCommitInfo],
        indicesOfCommits: [OID: Int],
        settings: GGSettings
    ) throws -> [GGBranchInfo] {
        var branchIdx = 0
        var branches = try extractBranches(repository: repository, commits: commits, indicesOfCommits: indicesOfCommits, settings: settings)

        // Create index mapping
        var indexMap = Array(repeating: Optional<Int>.none, count: branches.count)
        var commitCountPerBranch = Array(repeating: 0, count: branches.count)

        // First pass: trace branches and create initial mapping
        for oldIdx in 0..<branches.count {
            let branch = branches[oldIdx]
            let target = branch.target
            let isTag = branch.isTag
            let isMerged = branch.isMerged

            if let idx = indicesOfCommits[target] {
                if isTag {
                    commits[idx].tags.append(oldIdx)
                } else if !isMerged {
                    commits[idx].branches.append(oldIdx)
                }

                let oid = commits[idx].oid
                let hasClaimedCommits = (try? traceBranch(
                    repository: repository,
                    commits: &commits,
                    indicesOfCommits: indicesOfCommits,
                    branches: &branches,
                    commitOID: oid,
                    branchIndex: oldIdx
                )) ?? false

                if hasClaimedCommits || !isMerged {
                    branchIdx += 1
                    indexMap[oldIdx] = branchIdx - 1
                }
            }
        }

        // Count commits per branch
        for info in commits {
            if let trace = info.branchTrace {
                commitCountPerBranch[trace] += 1
            }
        }

        // Second pass: adjust mapping based on commit count
        var countSkipped = 0
        for idx in 0..<branches.count {
            if let mapped = indexMap[idx] {
                if commitCountPerBranch[idx] == 0 && branches[idx].isMerged && !branches[idx].isTag {
                    indexMap[idx] = nil
                    countSkipped += 1
                } else {
                    indexMap[idx] = mapped - countSkipped
                }
            }
        }

        // Update commit branch references
        for idx in commits.indices {
            if let trace = commits[idx].branchTrace {
                commits[idx].branchTrace = indexMap[trace]

                commits[idx].branches = commits[idx].branches.compactMap { br in
                    indexMap[br]
                }

                commits[idx].tags = commits[idx].tags.compactMap { tag in
                    indexMap[tag]
                }
            }
        }

        // Filter and return final branches
        return branches.enumerated().compactMap { (arrIndex, branch) in
            indexMap[arrIndex].map { _ in branch }
        }
    }

    /// Extracts (real or derived from merge summary) and assigns basic properties.
    static func extractBranches(
        repository: Repository,
        commits: [GGCommitInfo],
        indicesOfCommits: [OID: Int],
        settings: GGSettings
    ) throws -> [GGBranchInfo] {

        // Get actual branches from repository
        let type: BranchIterator.IteratorType = settings.includeRemote ? .all : .local
        let branchIterator = BranchIterator(repo: repository, type: type)
        var branchInfos = [GGBranchInfo]()
        var counter = 0

        while let branch = try? branchIterator.next()?.get() {
            if branch.isSymbolic { continue }
            let target = branch.oid

            counter += 1
            let name = branch.name
            let endIndex = indicesOfCommits[target]

            let termColor = try toTerminalColor(
                branchColor(
                    name: name,
                    colors: settings.branches.terminalColors,
                    unknownColors: settings.branches.terminalColorsUnknown,
                    counter: counter
                )
            )

            let svgColor = branchColor(
                name: name,
                colors: settings.branches.svgColors,
                unknownColors: settings.branches.svgColorsUnknown,
                counter: counter
            )

            let branchInfo = GGBranchInfo(
                target: target,
                mergeTarget: nil,
                name: name,
                persistence: UInt8(branchOrder(name: name, patterns: settings.branches.persistence)),
                isRemote: branch.isRemote,
                isMerged: false,
                isTag: false,
                visual: GGBranchVis(
                    orderGroup: branchOrder(name: name, patterns: settings.branches.order),
                    termColor: termColor,
                    svgColor: svgColor
                ),
                endIndex: endIndex
            )
            branchInfos.append(branchInfo)
        }

        // Process merge commits
        for (idx, info) in commits.enumerated() {
            guard info.isMerge,
                  let parentOid = info.parents.last else {
                continue
            }

            counter += 1
            let branchName = parseMergeSummary(info.summary, patterns: settings.mergePatterns) ?? "unknown"

            let persistence = UInt8(branchOrder(name: branchName, patterns: settings.branches.persistence))
            let position = branchOrder(name: branchName, patterns: settings.branches.order)

            let termColor = try toTerminalColor(
                branchColor(
                    name: branchName,
                    colors: settings.branches.terminalColors,
                    unknownColors: settings.branches.terminalColorsUnknown,
                    counter: counter
                )
            )

            let svgColor = branchColor(
                name: branchName,
                colors: settings.branches.svgColors,
                unknownColors: settings.branches.svgColorsUnknown,
                counter: counter
            )

            let branchInfo = GGBranchInfo(
                target: parentOid,
                mergeTarget: info.oid,
                name: branchName,
                persistence: persistence,
                isRemote: false,
                isMerged: true,
                isTag: false,
                visual: GGBranchVis(
                    orderGroup: position,
                    termColor: termColor,
                    svgColor: svgColor
                ),
                endIndex: idx + 1
            )

            branchInfos.append(branchInfo)
        }

        // Sort branches by persistence and merge status
        branchInfos.sort { a, b in
            if a.persistence == b.persistence {
                return a.isMerged && !b.isMerged
            }
            return a.persistence < b.persistence
        }


        // Process tags
        let tags = repository.allTags().mustSucceed()

        for tag in tags {
            guard let targetIndex = indicesOfCommits[tag.oid] else {
                continue
            }

            let tagName = if tag.longName.hasPrefix("refs/") {
                String(tag.longName.dropFirst(5))
            } else {
                tag.longName
            }

            counter += 1
            let termColor = try toTerminalColor(
                branchColor(
                    name: tagName,
                    colors: settings.branches.terminalColors,
                    unknownColors: settings.branches.terminalColorsUnknown,
                    counter: counter
                )
            )

            let position = branchOrder(name: tagName, patterns: settings.branches.order)
            let svgColor = branchColor(
                name: tagName,
                colors: settings.branches.svgColors,
                unknownColors: settings.branches.svgColorsUnknown,
                counter: counter
            )

            let tagInfo = GGBranchInfo(
                target: tag.oid,
                mergeTarget: nil,
                name: tagName,
                persistence: UInt8(settings.branches.persistence.count + 1),
                isRemote: false,
                isMerged: false,
                isTag: true,
                visual: GGBranchVis(
                    orderGroup: position,
                    termColor: termColor,
                    svgColor: svgColor
                ),
                endIndex: targetIndex
            )

            branchInfos.append(tagInfo)
        }
        return branchInfos
    }

    /// Traces back branches by following 1st commit parent,
    /// until a commit is reached that already has a trace.
    static func traceBranch(
        repository: Repository,
        commits: inout [GGCommitInfo],
        indicesOfCommits: [OID: Int],
        branches: inout [GGBranchInfo],
        commitOID: OID,
        branchIndex: Int
    ) throws -> Bool {
        var currentCommitId = commitOID
        var lastSeenPosition: Int?
        var branchStartPosition: Int?
        var hasClaimedCommits = false

        // Keep walking back through history until we can't find any more commits
        while let index = indicesOfCommits[currentCommitId] {
            // Have we hit a commit that's already claimed by another branch?
            let info = commits[index]
            if let oldTrace = info.branchTrace {
                // Get properties of old branch
                let oldBranch = branches[oldTrace]
                let oldName = oldBranch.name
                let oldTermColor = oldBranch.visual.termColor
                let oldSvgColor = oldBranch.visual.svgColor
                let oldRange = oldBranch.verticalSpan

                // Get properties of new branch
                let newName = branches[branchIndex].name
                let oldEnd = oldRange.start ?? 0
                let newEnd = branches[branchIndex].verticalSpan.start ?? 0

                if newName == oldName && oldEnd >= newEnd {
                    // Update old branch range
                    if let oldEndRange = oldRange.end {
                        if index > oldEndRange {
                            branches[oldTrace].verticalSpan = .init()
                        } else {
                            branches[oldTrace].verticalSpan = .init(index, oldRange.end)
                        }
                    } else {
                        branches[oldTrace].verticalSpan = .init(index, oldRange.end)
                    }
                } else {
                    // Handle origin branches
                    if branches[branchIndex].name.hasPrefix(ORIGIN) &&
                        branches[branchIndex].name.dropFirst(7) == oldName {
                        branches[branchIndex].visual.termColor = oldTermColor
                        branches[branchIndex].visual.svgColor = oldSvgColor
                    }

                    // Set start index based on previous index
                    if let prevIndex = lastSeenPosition {
                        // TODO: in cases where no crossings occur, the rule for merge commits can also be applied to normal commits
                        // see also print::get_deviate_index()
                        if commits[prevIndex].isMerge {
                            var tempIndex = prevIndex
                            for siblingOid in commits[index].children where siblingOid != currentCommitId {
                                if let siblingIndex = indicesOfCommits[siblingOid], siblingIndex > tempIndex {
                                    tempIndex = siblingIndex
                                }
                            }
                            branchStartPosition = tempIndex
                        } else {
                            branchStartPosition = index - 1
                        }
                    } else {
                        branchStartPosition = index - 1
                    }
                    break
                }
            }

            commits[index].branchTrace = branchIndex
            hasClaimedCommits = true

            let commit = try repository.commit(currentCommitId).get()
            if commit.parents.count == 0 {
                branchStartPosition = index
                break
            } else {
                lastSeenPosition = index
                currentCommitId = commit.parents.first!.oid
            }
        }

        // Update branch range
        if let end = branches[branchIndex].verticalSpan.start {
            if let start = branchStartPosition {
                if start < end {
                    // TODO: find a better solution (bool field?) to identify non-deleted branches
                    // that were not assigned to any commits, and thus should not occupy a column.
                    branches[branchIndex].verticalSpan = .init()
                } else {
                    branches[branchIndex].verticalSpan = .init(branches[branchIndex].verticalSpan.start, start)
                }
            } else {
                branches[branchIndex].verticalSpan = .init(branches[branchIndex].verticalSpan.start, nil)
            }
        } else {
            branches[branchIndex].verticalSpan = .init(branches[branchIndex].verticalSpan.start, branchStartPosition)
        }

        return hasClaimedCommits
    }

    static func branchColor<T>(
        name: String,
        colors: [(pattern: NSRegularExpression, colors: [T])],
        unknownColors: [T],
        counter: Int
    ) -> T {
        // Find matching color pattern
        if let (_, colorArray) = colors.first(where: { pattern, _ in
            if name.hasPrefix(ORIGIN) {
                let subName = String(name.dropFirst(7))
                return pattern.firstMatch(in: subName, range: NSRange(subName.startIndex..., in: subName)) != nil
            } else {
                return pattern.firstMatch(in: name, range: NSRange(name.startIndex..., in: name)) != nil
            }
        }) {
            return colorArray[counter % colorArray.count]
        }

        // Return from unknown colors if no pattern matches
        return unknownColors[counter % unknownColors.count]
    }

    /// Finds the index for a branch name from an array of regex patterns
    static func branchOrder(name: String, patterns: [NSRegularExpression]) -> Int {
        if let index = patterns.firstIndex(where: { pattern in
            if name.hasPrefix(ORIGIN) {
                let subName = String(name.dropFirst(7))
                return pattern.firstMatch(in: subName, range: NSRange(subName.startIndex..., in: subName)) != nil
            } else {
                return pattern.firstMatch(in: name, range: NSRange(name.startIndex..., in: name)) != nil
            }
        }) {
            return index
        }

        return patterns.count
    }

    /// Tries to extract the name of a merged-in branch from the merge commit summary
    static func parseMergeSummary(_ summary: String, patterns: GGMergePatterns) -> String? {
        for pattern in patterns.patterns {
            guard let match = pattern.firstMatch(in: summary, range: NSRange(summary.startIndex..., in: summary)),
                  match.numberOfRanges == 2 else {
                continue
            }

            let captureRange = match.range(at: 1)
            if captureRange.location != NSNotFound,
               let range = Range(captureRange, in: summary) {
                return String(summary[range])
            }
        }

        return nil
    }

    static func correctForkMerges(
        commits: [GGCommitInfo],
        indicesOfCommits: [OID: Int],
        branches: inout [GGBranchInfo],
        settings: GGSettings
    ) throws {
        for idx in 0..<branches.count {
            // Chain of optional bindings to get merge target branch
            if let mergeTargetOid = branches[idx].mergeTarget,
               let mergeTargetIndex = indicesOfCommits[mergeTargetOid],
               let commitInfo = commits[safe: mergeTargetIndex],
               let branchTrace = commitInfo.branchTrace,
               let mergeTarget = branches[safe: branchTrace],
               branches[idx].name == mergeTarget.name {

                // Create fork name
                let name = FORK + branches[idx].name

                // Get terminal color
                let termColor = try toTerminalColor(
                    Self.branchColor(
                        name: name,
                        colors: settings.branches.terminalColors,
                        unknownColors: settings.branches.terminalColorsUnknown,
                        counter: idx
                    )
                )

                // Get position and SVG color
                let position = Self.branchOrder(name: name, patterns: settings.branches.order)
                let svgColor = Self.branchColor(
                    name: name,
                    colors: settings.branches.svgColors,
                    unknownColors: settings.branches.svgColorsUnknown,
                    counter: idx
                )

                // Update branch info
                branches[idx].name = FORK + branches[idx].name
                branches[idx].visual.orderGroup = position
                branches[idx].visual.termColor = termColor
                branches[idx].visual.svgColor = svgColor
            }
        }
    }

    static func assignSourcesTargets(
        commits: [GGCommitInfo],
        indicesOfCommits: [OID: Int],
        branches: inout [GGBranchInfo]
    ) {
        // Assign target branches
        for idx in 0..<branches.count {
            let targetBranchIdx = branches[idx].mergeTarget
                .flatMap { oid in indicesOfCommits[oid] }
                .flatMap { idx in commits[safe: idx] }
                .flatMap { info in info.branchTrace }

            branches[idx].targetBranch = targetBranchIdx

            let group = targetBranchIdx
                .flatMap { trace in branches[safe: trace] }
                .map { branch in branch.visual.orderGroup }

            branches[idx].visual.targetOrderGroup = group
        }

        // Assign source branches
        for info in commits {
            var maxParentOrder: Int?
            var sourceBranchId: Int?

            // Check each parent commit
            for parentOid in info.parents {
                if let parentIdx = indicesOfCommits[parentOid],
                   let parentInfo = commits[safe: parentIdx],
                   parentInfo.branchTrace != info.branchTrace {

                    // Update source branch ID
                    if let trace = parentInfo.branchTrace {
                        sourceBranchId = trace
                    }

                    // Get parent branch group
                    let group = parentInfo.branchTrace
                        .flatMap { trace in branches[safe: trace] }
                        .map { branch in branch.visual.orderGroup }

                    // Update max parent order if needed
                    if let currentMax = maxParentOrder,
                       let parentGroup = group,
                       parentGroup > currentMax {
                        maxParentOrder = group
                    } else if maxParentOrder == nil {
                        maxParentOrder = group
                    }
                }
            }

            // Update branch information
            if let trace = info.branchTrace,
               let branchIndex = branches.indices.contains(trace) ? trace : nil {
                if let order = maxParentOrder {
                    branches[branchIndex].visual.sourceOrderGroup = order
                }
                if let sourceId = sourceBranchId {
                    branches[branchIndex].sourceBranch = sourceId
                }
            }
        }
    }

    /// Sorts branches into columns for visualization, ensuring all branches can be
    /// visualized linearly and without overlaps. Uses Shortest-First scheduling.
    static func assignBranchColumns(
        commits: [GGCommitInfo],
        indicesOfCommits: [OID: Int],
        branches: inout [GGBranchInfo],
        branchSettings: GGBranchSettings,
        shortestFirst: Bool,
        forward: Bool
    ) {
        // Initialize column tracking for each order group
        var occupied: [[[(start: Int, end: Int)]]] = Array(
            repeating: [],
            count: branchSettings.order.count + 1
        )

        let lengthSortFactor = shortestFirst ? 1 : -1
        let startSortFactor = forward ? 1 : -1

        // First pass: Build merge relationships map
        // This helps us track which commits are merged into other commits
        var mergeRelationships: [OID: OID] = [:]
        for commit in commits {
            if commit.isMerge && commit.parents.count > 1 {
                // For merge commits, we store the relationship between the second parent
                // and the merge commit itself
                mergeRelationships[commit.parents[1]] = commit.oid
            }
        }

        // Second pass: Build parent trace map considering both direct parentage
        // and merge relationships
        var parentTraceMap: [OID: Int] = [:]
        for commit in commits {
            // First check if this commit is merged into another commit
            if let mergeCommitId = mergeRelationships[commit.oid],
               let mergeIdx = indicesOfCommits[mergeCommitId],
               let mergeTrace = commits[mergeIdx].branchTrace {
                // If it is merged, use the merge commit's trace as the parent trace
                parentTraceMap[commit.oid] = mergeTrace
                continue
            }

            // If not merged, handle regular parent relationship
            // We use the first parent as the main line of history
            if !commit.parents.isEmpty,
               let parentIdx = indicesOfCommits[commit.parents[0]],
               let parentTrace = commits[parentIdx].branchTrace {
                parentTraceMap[commit.oid] = parentTrace
            }
        }

        // Create sortable branch data
        var branchesSort = branches.enumerated()
            .filter { _, br in
                br.verticalSpan.start != nil || br.verticalSpan.end != nil
            }
            .map { idx, br in (
                idx: idx,
                start: br.verticalSpan.start ?? 0,
                end: br.verticalSpan.end ?? (branches.count - 1),
                sourceGroup: br.visual.sourceOrderGroup ?? branchSettings.order.count + 1,
                targetGroup: br.visual.targetOrderGroup ?? branchSettings.order.count + 1,
                branch: br
            )}

        // Sort branches with enhanced criteria to handle traces and merges properly
        branchesSort.sort { a, b in
            // Get trace information for comparison
            let currentTraceA = indicesOfCommits[a.branch.target]
                .flatMap { commits[$0].branchTrace } ?? 999
            let parentTraceA = parentTraceMap[a.branch.target] ?? 999

            let currentTraceB = indicesOfCommits[b.branch.target]
                .flatMap { commits[$0].branchTrace } ?? 999
            let parentTraceB = parentTraceMap[b.branch.target] ?? 999

            // Primary sorting: main branch (trace 0) comes first
            if (currentTraceA == 0) != (currentTraceB == 0) {
                return currentTraceA == 0
            }

            // Secondary sorting: group by parent trace
            if parentTraceA != parentTraceB {
                return parentTraceA < parentTraceB
            }

            // Tertiary sorting: handle branch splits
            let isSplitA = currentTraceA != parentTraceA
            let isSplitB = currentTraceB != parentTraceB
            if isSplitA != isSplitB {
                return !isSplitA
            }

            // Final sorting criteria for equal cases
            let maxGroupA = max(a.sourceGroup, a.targetGroup)
            let maxGroupB = max(b.sourceGroup, b.targetGroup)
            if maxGroupA != maxGroupB {
                return maxGroupA < maxGroupB
            }

            let lengthA = (a.end - a.start) * lengthSortFactor
            let lengthB = (b.end - b.start) * lengthSortFactor
            if lengthA != lengthB {
                return lengthA < lengthB
            }

            return a.start * startSortFactor < b.start * startSortFactor
        }

        // Track column assignments for each trace
        var traceColumns: [Int: Int] = [:]

        // Assign columns to branches
        for branchData in branchesSort {
            let branch = branches[branchData.idx]
            let group = branch.visual.orderGroup

            let currentTrace = indicesOfCommits[branch.target]
                .flatMap { commits[$0].branchTrace }
            let parentTrace = parentTraceMap[branch.target]

            // Determine if this branch splits from its parent
            let isBranchSplit = currentTrace != nil && parentTrace != nil &&
            currentTrace! != parentTrace!

            let len = occupied[group].count
            var found = len

            // Only search for existing columns if this isn't a branch split
            if !isBranchSplit {
                for i in 0..<len {
                    let columnOcc = occupied[group][i]
                    var isOccupied = false

                    // Check for range conflicts
                    for (start, end) in columnOcc {
                        if branchData.start <= end && branchData.end >= start {
                            isOccupied = true
                            break
                        }
                    }

                    if !isOccupied {
                        found = i
                        break
                    }
                }
            }

            // Update branch column
            branches[branchData.idx].visual.column = found

            // Track trace column assignments
            if let trace = currentTrace {
                traceColumns[trace] = found
            }

            // Create new column if needed
            if found == occupied[group].count {
                occupied[group].append([])
            }
            occupied[group][found].append((branchData.start, branchData.end))
        }

        // Calculate final group offsets
        let groupOffset = occupied.reduce(into: [Int]()) { result, group in
            result.append((result.last ?? 0) + group.count)
        }

        // Apply offsets to get final column positions
        for i in branches.indices {
            if let column = branches[i].visual.column {
                let offset = branches[i].visual.orderGroup == 0 ? 0 :
                groupOffset[branches[i].visual.orderGroup - 1]
                branches[i].visual.column = column + offset
            }
        }
    }
}

enum GGError: Error {
    case shallowCloneNotSupported
}
