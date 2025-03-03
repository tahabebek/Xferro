//
//  RepositoryHistoryView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct RepositoryHistoryView: View {
    let historyCommits: [SelectableHistoryCommit]

    var body: some View {
        if historyCommits.isNotEmpty {
            RepositoryActualHistoryView(historyCommits: historyCommits)
        } else {
            RepositoryEmptyView()
        }
    }
}
