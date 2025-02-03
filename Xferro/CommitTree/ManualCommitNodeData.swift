//
//  NodeData.swift
//  Xferro
//
//  Created by Taha Bebek on 1/13/25.
//

import Foundation
import SwiftUI

class ManualCommitNodeData: NodeData {
    var id: String { oid.description }
    let commit: AnyCommit

    var isMarked: Bool { commit.isMarked }
    var oid: OID { commit.commit.oid }

    var color: Color {
        Color(nsColor: currentTheme.primary)
    }

    var selectedColor: Color {
        Color(nsColor: currentTheme.darkPrimary)
    }

    var shape: TreeNodeShape {
        .circle(radius: 16)
    }

    init(commit: AnyCommit) {
        self.commit = commit
    }

    static func == (lhs: ManualCommitNodeData, rhs: ManualCommitNodeData) -> Bool {
        lhs.id == rhs.id
    }
}
