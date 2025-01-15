//
//  AutoCommitNodeData.swift
//  Xferro
//
//  Created by Taha Bebek on 1/13/25.
//

import SwiftUI

class AutoCommitNodeData: Equatable, NodeData {
    var id: String {
        commits.reduce("", { partialResult, commit in
            "\(partialResult)\(commit.commit.oid)"
        })
    }
    var commits: [AnyCommit] = []

    var color: Color {
        Color(nsColor: currentTheme.primary)
    }

    var selectedColor: Color {
        Color(nsColor: currentTheme.darkPrimary)
    }

    var shape: TreeNodeShape {
        .rectangle(width: 4, height: 4)
    }

    static func == (lhs: AutoCommitNodeData, rhs: AutoCommitNodeData) -> Bool {
        lhs.id == rhs.id && lhs.commits == rhs.commits
    }
}
