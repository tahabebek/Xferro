//
//  RepositoryView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import Observation
import SwiftUI

struct RepositoryView: View {
    @Environment(CommitsViewModel.self) var viewModel
    @State private var isCollapsed = false
    @State private var selection: Int = 0
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
                VStack(spacing: 16) {
                    Picker(selection: $selection) {
                        Group {
                            Text("Branches")
                                .tag(0)
                                .foregroundColor(selection == 0 ? .white : Color.white.opacity(0.5))
                            Text("Tags")
                                .tag(1)
                                .foregroundColor(selection == 1 ? .white : Color.white.opacity(0.5))
                            Text("Stashes")
                                .tag(2)
                                .foregroundColor(selection == 2 ? .white : Color.white.opacity(0.5))
                            Text("History")
                                .tag(3)
                                .foregroundColor(selection == 3 ? .white : Color.white.opacity(0.5))
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
                    .frame(height: 32)
                    contentView
                        .padding(.bottom, 8)
                }
                .animation(.default, value: selection)
                .frame(maxHeight: !isCollapsed ? .infinity : 0)
            }
            .padding()
        }
        .background(
            Color(hex: 0x15151A)
                .cornerRadius(8)
        )
    }

    @ViewBuilder private var contentView: some View {
        switch selection {
        case 0:
            branchesView
                .matchedGeometryEffect(id: "container", in: animation)
        case 1:
            tagsView
                .matchedGeometryEffect(id: "container", in: animation)
        case 2:
            stashesView
                .matchedGeometryEffect(id: "container", in: animation)
        case 3:
            historyView
                .matchedGeometryEffect(id: "container", in: animation)
        default:
            fatalError()
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
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top) {
                ForEach(viewModel.tagReferences(for: repository)) { tagReference in
                    FlaredRounded {
                        VStack {
                            Text("\(tagReference.name)")
                                .font(.largeTitle)
                                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                            Text("\(tagReference.oid.debugOID.prefix(4))")
                                .font(.footnote)
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

    private var stashesView: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top) {
                ForEach(viewModel.stashes(for: repository)) { stash in
                    FlaredRounded {
                        VStack {
                            Text("\(stash.oid.debugOID.prefix(4))")
                                .font(.largeTitle)
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
