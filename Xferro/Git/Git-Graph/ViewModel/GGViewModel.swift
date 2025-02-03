//
//  GGViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 1/30/25.
//

import Foundation
import Observation

@Observable final class GGViewModel {
    var nodes: [GitGraphNode] = []
    private var gitGraph: GitGraph

    init(gitGraph: GitGraph, config: GitGraphViewConfiguration = .init()) {
        self.gitGraph = gitGraph
        var realBranches: [GGBranchInfo] = []
        for i in gitGraph.branches {
            realBranches.append(gitGraph.allBranches[i])
        }
        self.nodes = createGraphNodes(commits: gitGraph.commits, branches: realBranches)
    }

    func createGraphNodes(
        commits: [GGCommitInfo],
        branches: [GGBranchInfo]
    ) -> [GitGraphNode] {
        print("\n=== Starting Graph Node Creation ===\n")

        // First, let's see what branches we're working with
        print("Branches:")
        for (index, branch) in branches.enumerated() {
            print("Branch \(index):")
            print("  Target: \(branch.target) (short: \(branch.target.description.prefix(7)))")
            print("  Name: \(branch.name)")
            print("  Vertical Span: \(branch.verticalSpan)")
            print("  Order Group: \(branch.visual.orderGroup)")
            if let column = branch.visual.column {
                print("  Column: \(column)")
            }
            print("")
        }

        // Now let's examine our commits
        print("\nCommits:")
        for (index, commit) in commits.enumerated() {
            print("\nCommit \(index):")
            print("  OID: \(commit.shortOID)")
            print("  Is Merge: \(commit.isMerge)")
            print("  Parents: \(commit.parents.map { $0.description.prefix(7) })")
            print("  Branch Trace: \(String(describing: commit.branchTrace))")
            print("  Branches: \(commit.branches)")
        }

        // Track which branches are associated with each commit
        var branchLabelsMap: [OID: [String]] = [:]
        for branch in branches {
            if branchLabelsMap[branch.target] == nil {
                branchLabelsMap[branch.target] = []
            }
            let branchName = branch.isRemote ? branch.name :
            branch.name.split(separator: "/").last.map(String.init) ?? branch.name
            branchLabelsMap[branch.target]?.append(branchName)
        }

        print("\nCreating graph connections:")
        var nodes: [GitGraphNode] = []
        for (index, commit) in commits.enumerated() {
            let connections = commit.parents.compactMap { parentOID -> GitGraphConnection? in
                guard let parentIndex = commits.firstIndex(where: { $0.oid == parentOID }) else {
                    print("  Warning: Parent \(parentOID.description.prefix(7)) not found for commit \(commit.shortOID)")
                    return nil
                }

                let isMerge = commit.isMerge && commit.parents.firstIndex(of: parentOID) != 0
                let connection = GitGraphConnection(
                    fromColumn: commit.branchTrace ?? 0,
                    toColumn: commits[parentIndex].branchTrace ?? 0,
                    fromRow: index,
                    toRow: parentIndex,
                    isMerge: isMerge
                )

                print("  Connection for commit \(commit.shortOID):")
                print("    From column: \(connection.fromColumn)")
                print("    To column: \(connection.toColumn)")
                print("    From row: \(connection.fromRow)")
                print("    To row: \(connection.toRow)")
                print("    Is merge: \(connection.isMerge)")

                return connection
            }

            let node = GitGraphNode(
                id: commit.oid.description,
                message: commit.summary,
                column: commit.branchTrace ?? 0,
                row: index,
                commitHash: commit.shortOID,
                branchLabels: branchLabelsMap[commit.oid] ?? [],
                connections: connections
            )

            print("\nCreated node for commit \(commit.shortOID):")
            print("  Column: \(node.column)")
            print("  Row: \(node.row)")
            print("  Branch labels: \(node.branchLabels)")
            print("  Number of connections: \(node.connections.count)")

            nodes.append(node)
        }

        print("\n=== Graph Node Creation Complete ===\n")
        return nodes
    }
}
