//
//  RepositoryView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import Observation
import SwiftUI

struct RepositoryView: View {
    enum Section: Int {
        case commits = 0
        case tags = 1
        case stashes = 2
        case history = 3
    }

    let repositoryInfo: RepositoryInfo
    @State private var isCollapsed = false
    @State private var selection: Section = .commits
    @State private var isMinimized: Bool = false

    var body: some View {
        Group {
            VStack(spacing: 0) {
                RepositoryMenuView(
                    isCollapsed: $isCollapsed,
                    gitDir: repositoryInfo.repository.gitDir) {
                        repositoryInfo.deleteRepositoryTapped()
                    }
                    .frame(height: isMinimized ? 54 : 36)
                if !isCollapsed {
                    VStack(spacing: 16) {
                        RepositoryPickerView(selection: $selection)
                            .frame(height: 24)
                        RepositoryContentView(
                            selection: selection,
                            tags: repositoryInfo.tags,
                            stashes: repositoryInfo.stashes,
                            historyCommits: repositoryInfo.historyCommits,
                            detachedTag: repositoryInfo.detachedTag,
                            detachedCommit: repositoryInfo.detachedCommit,
                            localBranches: repositoryInfo.localBranchInfos,
                            onUserTapped: repositoryInfo.onUserTapped,
                            onIsSelected: repositoryInfo.onIsSelected,
                            onDeleteBranchTapped: repositoryInfo.onDeleteBranchTapped,
                            onIsCurrentBranch: repositoryInfo.onIsCurrentBranch,
                            onPushBranchToRemoteTapped: repositoryInfo.onPushBranchToRemoteTapped,
                            selectableStatus: SelectableStatus(repositoryInfo: repositoryInfo),
                            head: repositoryInfo.head
                        )
                        .padding(.bottom, 8)
                }
                    .frame(maxHeight: !isCollapsed ? .infinity : 0)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, !isCollapsed ? 8 : 0)
        }
        .animation(.default, value: repositoryInfo.head)
        .animation(.default, value: isCollapsed)
        .animation(.default, value: isMinimized)
        .background(
            Color(hexValue: 0x15151A)
                .cornerRadius(8)
        )
    }
}
