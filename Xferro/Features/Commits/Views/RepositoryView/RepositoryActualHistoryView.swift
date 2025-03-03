//
//  RepositoryActualHistoryView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct RepositoryActualHistoryView: View {
    let historyCommits: [SelectableHistoryCommit]
    
    var body: some View {
        EmptyView()
            .animation(.default, value: historyCommits)
    }
}
