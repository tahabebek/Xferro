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

    @Environment(CommitsViewModel.self) var commitsViewModel
    @State private var isCollapsed = false
    @State private var selection: Section = .commits
    @State var isMinimized: Bool = false
    @Namespace private var animation
    @State var repositoryInfo: RepositoryInfo

    var body: some View {
        Group {
            VStack(spacing: 0) {
                menu
                .frame(height: isMinimized ? 54 : 36)
                if !isCollapsed {
                    VStack(spacing: 16) {
                        ViewThatFits(in: .horizontal) {
                            picker
                            smallPicker
                        }
                        .frame(height: 24)

                        contentView
                            .padding(.bottom, 8)
                    }
                    .animation(.default, value: selection)
                    .frame(maxHeight: !isCollapsed ? .infinity : 0)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, !isCollapsed ? 8 : 0)
        }
        .animation(.default, value: commitsViewModel.currentRepositoryInfos)
        .animation(.default, value: commitsViewModel.currentSelectedItem)
        .animation(.default, value: isCollapsed)
        .animation(.default, value: selection)
        .animation(.default, value: isMinimized)
        .background(
            Color(hex: 0x15151A)
                .cornerRadius(8)
        )
    }

    private var menu: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                label
                Spacer()
                actionsView
                Spacer()
                navigationView
            }
            VStack(spacing: 6) {
                smallLabel
                HStack {
                    actionsView
                    navigationView
                }
            }
            .onAppear {
                isMinimized = true
            }
            .onDisappear {
                isMinimized = false
            }
            VStack(spacing: 6) {
                smallLabel
                navigationView
            }
            .onAppear {
                isMinimized = true
            }
            .onDisappear {
                isMinimized = false
            }
        }
    }

    @ViewBuilder private var label: some View {
        if let currentRepository = commitsViewModel.currentSelectedItem?.repository.nameOfRepo,
           currentRepository == repositoryInfo.repository.nameOfRepo
        {
            Label(repositoryInfo.repository.gitDir.deletingLastPathComponent().lastPathComponent, systemImage: "folder")
                .foregroundStyle(Color.accentColor)
                .fixedSize()
        } else {
            Label(repositoryInfo.repository.gitDir.deletingLastPathComponent().lastPathComponent, systemImage: "folder")
                .fixedSize()
        }
    }

    @ViewBuilder private var smallLabel: some View {
        if let currentRepository = commitsViewModel.currentSelectedItem?.repository.nameOfRepo,
           currentRepository == repositoryInfo.repository.nameOfRepo
        {
            Text(repositoryInfo.repository.gitDir.deletingLastPathComponent().lastPathComponent)
                .foregroundStyle(Color.accentColor)
                .fixedSize()
        } else {
            Text(repositoryInfo.repository.gitDir.deletingLastPathComponent().lastPathComponent)
                .fixedSize()
        }
    }

    private var actionsView: some View {
        HStack {
            Image(systemName: "arrow.down")
                .contentShape(Rectangle())
                .hoverableButton("Pull changes from remote") {}
            Image(systemName: "arrow.up")
                .contentShape(Rectangle())
                .hoverableButton("Push changes to remote") {}
            Image(systemName: "cursorarrow.click.2")
                .contentShape(Rectangle())
                .hoverableButton("Checkout to a remote branch") {}
        }
    }

    private var navigationView: some View {
        HStack {
            Image(systemName: "xmark")
                .contentShape(Rectangle())
                .hoverableButton("Remove Repository") {
                    withAnimation(.easeInOut) {
                        commitsViewModel.deleteRepositoryButtonTapped(repositoryInfo.repository)
                    }
                }
            Image(systemName: "chevron.down")
                .rotationEffect(Angle(degrees: !isCollapsed ? -180 : 0))
                .contentShape(Rectangle())
                .hoverableButton(isCollapsed ? "Expand" : "Collapse") {
                    withAnimation(.easeInOut) {
                        isCollapsed.toggle()
                    }
                }
        }
    }

    private var smallPicker: some View {
        Picker(selection: $selection) {
            Group {
                Text("C")
                    .tag(Section.commits)
                Text("T")
                    .tag(Section.tags)
                Text("S")
                    .tag(Section.stashes)
                Text("H")
                    .tag(Section.history)
            }
            .font(.callout)
        } label: {
            Text("Hidden Label")
        }
        .pickerStyle()
    }

    private var picker: some View {
        Picker(selection: $selection) {
            Group {
                Text("Commits")
                    .tag(Section.commits)
                Text("Tags")
                    .tag(Section.tags)
                Text("Stashes")
                    .tag(Section.stashes)
                Text("History")
                    .tag(Section.history)
            }
            .font(.callout)
        } label: {
            Text("Hidden Label")
        }
        .pickerStyle()
    }

    @ViewBuilder private var contentView: some View {
        switch selection {
        case .commits:
            commitsView(
                detachedTag: repositoryInfo.detachedTag,
                detachedCommit: repositoryInfo.detachedCommit
            )
            .matchedGeometryEffect(id: "contentView", in: animation)
        case .tags:
            tagsView
                .matchedGeometryEffect(id: "contentView", in: animation)
        case .stashes:
            stashesView
                .matchedGeometryEffect(id: "contentView", in: animation)
        case .history:
            historyView
                .matchedGeometryEffect(id: "contentView", in: animation)
        }
    }

    private func commitsView(
        detachedTag: SelectableDetachedTag?,
        detachedCommit: SelectableDetachedCommit?
    ) -> some View {
        guard detachedTag == nil || detachedCommit == nil else {
            fatalError(.impossible)
        }
        return VStack(spacing: 16) {
            let repository = repositoryInfo.repository
            let status = SelectableStatus(repository: repository, head: repositoryInfo.head)
            let hasDetachedTagOrCommit = detachedTag != nil || detachedCommit != nil
            if let detachedTag {
                BranchView(
                    name: "Detached tag \(detachedTag.tag.name)",
                    selectableCommits: commitsViewModel.detachedCommits(of: detachedTag, in: repository),
                    selectableStatus: status,
                    isCurrent: true,
                    isDetached: true,
                    branchCount: repositoryInfo.localBranchInfos.count
                )
            } else if let detachedCommit {
                BranchView(
                    name: "Detached Commit",
                    selectableCommits: commitsViewModel.detachedAncestorCommitsOf(oid: detachedCommit.commit.oid, in: repository),
                    selectableStatus: status,
                    isCurrent: true,
                    isDetached: true,
                    branchCount: repositoryInfo.localBranchInfos.count
                )
            }
            ForEach(repositoryInfo.localBranchInfos) { branchInfo in
                BranchView(
                    name: branchInfo.branch.name,
                    selectableCommits: branchInfo.commits,
                    selectableStatus: status,
                    isCurrent: hasDetachedTagOrCommit ? false :
                        commitsViewModel.isCurrentBranch(branchInfo.branch, head: repositoryInfo.head, in: repository),
                    isDetached: false,
                    branchCount: repositoryInfo.localBranchInfos.count
                )
            }
        }
    }

    @ViewBuilder private var tagsView: some View {
        if repositoryInfo.tags.isEmpty {
            emptyView
        } else {
            actualTagsView(tags: repositoryInfo.tags)
        }
    }

    private func actualTagsView(tags: [SelectableTag]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top) {
                ForEach(tags) { selectableTag in
                    ZStack {
                        FlaredRounded {
                            VStack {
                                Text("\(selectableTag.tag.name)")
                                    .font(.title)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                                    .frame(maxWidth: 70)
                                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                                Text("\(selectableTag.tag.oid.debugOID.prefix(4))")
                                    .font(.footnote)
                                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                            }
                        }
                        .frame(width: 80, height: 80)
                        .onTapGesture {
                            commitsViewModel.userTapped(item: selectableTag)
                        }
                        if commitsViewModel.isSelected(item: selectableTag) {
                            SelectedItemOverlay(width: 80, height: 80)
                        }
                    }
                }
            }
            .fixedSize()
        }
        .flipsForRightToLeftLayoutDirection(true)
        .environment(\.layoutDirection, .rightToLeft)
    }

    @ViewBuilder private var stashesView: some View {
        if repositoryInfo.stashes.isEmpty {
            emptyView
        } else {
            actualStashesView(stashes: repositoryInfo.stashes)
        }
    }

    private func actualStashesView(stashes: [SelectableStash]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top) {
                ForEach(stashes) { selectableStash in
                    ZStack {
                        FlaredRounded {
                            VStack {
                                Text("\(selectableStash.stash.oid.debugOID.prefix(4))")
                                    .font(.title)
                                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                            }
                        }
                        .frame(width: 80, height: 80)
                        .onTapGesture {
                            commitsViewModel.userTapped(item: selectableStash)
                        }
                        if commitsViewModel.isSelected(item: selectableStash) {
                            SelectedItemOverlay(width: 80, height: 80)
                        }
                    }
                }
            }
            .fixedSize()
        }
        .flipsForRightToLeftLayoutDirection(true)
        .environment(\.layoutDirection, .rightToLeft)
    }

    private var emptyView: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                Text("Empty")
                Spacer()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var historyView: some View {
        emptyView
    }
}

private struct PickerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .labelsHidden()
            .padding(.trailing, 2)
            .background(Color(hex: 0x0B0C10))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .pickerStyle(SegmentedPickerStyle())
    }
}

private extension View {
    func pickerStyle() -> some View {
        modifier(PickerModifier())
    }
}
