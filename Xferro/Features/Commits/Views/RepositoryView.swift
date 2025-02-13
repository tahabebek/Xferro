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
    @Environment(RepositoryViewModel.self) var repositoryViewModel
    @State private var isCollapsed = false
    @State private var selection: Section = .commits
    @Namespace private var animation

    var body: some View {
        Group {
            VStack(spacing: 0) {
                HStack {
                    Label(repositoryViewModel.repositoryInfo.repository.gitDir.deletingLastPathComponent().lastPathComponent, systemImage: "folder")
                    HoverButton(hoverText: isCollapsed ? "Expand" : "Collapse") {
                        withAnimation(.easeInOut) {
                            isCollapsed.toggle()
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .frame(width: 36, height: 36)
                            .rotationEffect(Angle(degrees: !isCollapsed ? -180 : 0))
                            .contentShape(Rectangle())
                    }

                    Spacer()
                    HoverButton(hoverText: isCollapsed ? "Expand" : "Collapse") {
                        withAnimation(.easeInOut) {
                            isCollapsed.toggle()
                        }
                    } label: {
                        Image(systemName: "plus.app")
                            .frame(height: 36)
                            .contentShape(Rectangle())
                    }

                    HoverButton(hoverText: isCollapsed ? "Expand" : "Collapse") {
                        withAnimation(.easeInOut) {
                            isCollapsed.toggle()
                        }
                    } label: {
                        Image(systemName: "plus.square.on.square")
                            .frame(height: 36)
                            .contentShape(Rectangle())
                    }

//                    Button {
//                        withAnimation(.easeInOut) {
//                            isCollapsed.toggle()
//                        }
//                    } label: {
//                        Image(systemName: "chevron.down")
//                            .frame(width: 36, height: 36)
//                            .rotationEffect(Angle(degrees: !isCollapsed ? -180 : 0))
//                            .contentShape(Rectangle())
//                    }
//                    .buttonStyle(.borderless)
//                    Spacer()
//                    Button {
//                        withAnimation(.easeInOut) {
//                            isCollapsed.toggle()
//                        }
//                    } label: {
//                        Image(systemName: "plus.app")
//                            .frame(height: 36)
//                            .contentShape(Rectangle())
//                    }
//                    .buttonStyle(.borderless)
//                    .onHover { _ in
//                        
//                    }
//                    Button {
//                        withAnimation(.easeInOut) {
//                            isCollapsed.toggle()
//                        }
//                    } label: {
//                        Image(systemName: "plus.square.on.square")
//                            .frame(height: 36)
//                            .contentShape(Rectangle())
//                    }
//                    .buttonStyle(.borderless)
                }
                .frame(height: 36)
                if !isCollapsed {
                    VStack(spacing: 16) {
                        picker
                            .frame(height: 32)
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
        .background(
            Color(hex: 0x15151A)
                .cornerRadius(8)
        )
    }

    @ViewBuilder private var picker: some View {
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
        .labelsHidden()
        .padding(.trailing, 2)
        .background(Color(hex: 0x0B0C10))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .pickerStyle(SegmentedPickerStyle())
    }

    @ViewBuilder private var contentView: some View {
        switch selection {
        case .commits:
            commitsView
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

    private var commitsView: some View {
        VStack(spacing: 16) {
            let repositoryInfo = repositoryViewModel.repositoryInfo
            let repository = repositoryInfo.repository
            let head = Head.of(repository)
            let status = SelectableStatus(repository: repository)
            if let detachedTag = repositoryInfo.detachedTag {
                BranchView(
                    name: detachedTag.tag.name,
                    selectableCommits: commitsViewModel.detachedCommits(of: detachedTag, in: repository),
                    selectableStatus: status,
                    isCurrent: true
                )
            } else if let detachedCommit = repositoryInfo.detachedCommit {
                BranchView(
                    name: "Detached Commit",
                    selectableCommits: commitsViewModel.detachedAncestorCommitsOf(oid: detachedCommit.commit.oid, in: repository),
                    selectableStatus: status,
                    isCurrent: true
                )
            }
            ForEach(repositoryInfo.branchInfos) { branchInfo in
                BranchView(
                    name: branchInfo.branch.name,
                    selectableCommits: branchInfo.commits,
                    selectableStatus: status,
                    isCurrent: commitsViewModel.isCurrentBranch(branchInfo.branch, head: head, in: repository)
                )
            }
        }
    }

    private var tagsView: some View {
        let tags = repositoryViewModel.repositoryInfo.tags
        return Group {
            if tags.isEmpty {
                emptyView
            } else {
                actualTagsView(tags: tags)
            }
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

    private var stashesView: some View {
        let stashes = repositoryViewModel.repositoryInfo.stashes
        return Group {
            if stashes.isEmpty {
                emptyView
            } else {
                actualStashesView(stashes: stashes)
            }
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
