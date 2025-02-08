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

    @Environment(CommitsViewModel.self) var viewModel
    @State private var isCollapsed = false
    @State private var selection: Section = .commits
    @Namespace private var animation

    let repository: Repository

    var body: some View {
        Group {
            VStack(spacing: 0) {
                HStack {
                    Label(repository.gitDir?.deletingLastPathComponent().lastPathComponent ?? "Unkown", systemImage: "folder")
                    Spacer()
                    Button {
                        withAnimation(.easeInOut) {
                            isCollapsed.toggle()
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .frame(width: 36, height: 36)
                            .rotationEffect(Angle(degrees: !isCollapsed ? -180 : 0))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)

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
            let head = try? viewModel.HEAD(for: repository)
            if let detachedTag = viewModel.detachedTag(of: repository) {
                BranchView(
                    name: detachedTag.tag.name,
                    selectableCommits: viewModel.detachedCommits(of: detachedTag.tag.oid, in: repository),
                    selectableStatus: .init(repository: repository, type: .tag(detachedTag.tag)),
                    isCurrent: true
                )
            } else if let detachedCommit = viewModel.detachedCommit(of: repository) {
                BranchView(
                    name: "Detached Commit",
                    selectableCommits: viewModel.detachedCommits(of: detachedCommit.commit.oid, in: repository),
                    selectableStatus: .init(repository: repository, type: .detached(detachedCommit.commit)),
                    isCurrent: true
                )
            }
            ForEach(viewModel.branches(of: repository)) { branch in
                BranchView(
                    name: branch.name,
                    selectableCommits: viewModel.commits(of: branch, in: repository),
                    selectableStatus: .init(repository: repository, type: .branch(branch)),
                    isCurrent: (head != nil) ? viewModel.isCurrentBranch(branch, head: head!, in: repository) : false
                )
            }
        }
    }

    private var tagsView: some View {
        let tags = viewModel.tags(of: repository)
        return Group {
            if tags.isEmpty {
                emptyView
            } else {
                actualTagsView(tags: tags)
            }
        }
    }

    private func actualTagsView(tags: [CommitsViewModel.SelectableTag]) -> some View {
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
                            viewModel.userTapped(item: selectableTag)
                        }
                        if viewModel.isSelected(item: selectableTag) {
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
        let stashes = viewModel.stashes(of: repository)
        return Group {
            if stashes.isEmpty {
                emptyView
            } else {
                actualStashesView(stashes: stashes)
            }
        }
    }

    private func actualStashesView(stashes: [CommitsViewModel.SelectableStash]) -> some View {
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
                            viewModel.userTapped(item: selectableStash)
                        }
                        if viewModel.isSelected(item: selectableStash) {
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
