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
        case branches = 0
        case tags = 1
        case stashes = 2
        case history = 3
    }

    @Environment(CommitsViewModel.self) var viewModel
    @State private var isCollapsed = false
    @State private var selection: Section = .branches
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
                .padding(.bottom, !isCollapsed ? 16 : 0)
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
            .padding()
        }
        .background(
            Color(hex: 0x15151A)
                .cornerRadius(8)
        )
    }

    @ViewBuilder private var picker: some View {
        Picker(selection: $selection) {
            Group {
                Text("Branches")
                    .tag(Section.branches)
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
        case .branches:
            branchesView
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

    private var branchesView: some View {
        VStack(spacing: 16) {
            let head = try? viewModel.HEAD(for: repository)
            ForEach(viewModel.branches(for: repository)) { branch in
                BranchView(
                    branch: branch,
                    commits: viewModel.commitsForBranch(branch, in: repository),
                    isCurrentBranch: (head != nil) ? viewModel.isCurrentBranch(branch, head: head!, in: repository) : false
                )
            }
        }
    }

    private var tagsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top) {
                ForEach(viewModel.tagReferences(for: repository)) { tagReference in
                    FlaredRounded {
                        VStack {
                            Text("\(tagReference.name)")
                                .font(.title)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .frame(maxWidth: 70)
                                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                            Text("\(tagReference.oid.debugOID.prefix(4))")
                                .font(.footnote)
                                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        }
                    }
                    .frame(width: 80, height: 80)
                    .fixedSize()
                }
            }
            .fixedSize()
        }
        .flipsForRightToLeftLayoutDirection(true)
        .environment(\.layoutDirection, .rightToLeft)
    }

    private var stashesView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top) {
                ForEach(viewModel.stashes(for: repository)) { stash in
                    FlaredRounded {
                        VStack {
                            Text("\(stash.oid.debugOID.prefix(4))")
                                .font(.title)
                                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        }
                    }
                    .frame(width: 80, height: 80)
                }
            }
            .fixedSize()
        }
        .flipsForRightToLeftLayoutDirection(true)
        .environment(\.layoutDirection, .rightToLeft)
    }

    private var historyView: some View {
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
}
