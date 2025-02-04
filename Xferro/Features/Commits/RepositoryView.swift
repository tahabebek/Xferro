//
//  RepositoryView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import AxisSegmentedView
import Observation
import SwiftUI

struct RepositoryView: View {
    enum Selection {
        static let branches: Int   = 0
        static let tags: Int       = 1
        static let stashes: Int    = 2
        static let history: Int    = 3
    }

    @State var viewModel: CommitsViewModel
    @State private var isCollapsed = false
    @State private var selection: Int = Selection.tags
    @State private var normalValue: BranchSectionNormalValue = .init()

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
                    segmentedView
                        .frame(height: 32)
                    contentView
                }
                .opacity(!isCollapsed ? 1 : 0)
                .frame(maxHeight: !isCollapsed ? .infinity : 0)
            }
            .padding()
        }
        .background(
            Color(hex: 0x15151A)
                .cornerRadius(8)
        )
    }

    private var segmentedView: some View {
        AxisSegmentedView(selection: $selection, constant: normalValue.constant, {
            Group {
                Text("Branches")
                    .font(.callout)
                    .foregroundColor(Color.white.opacity(0.5))
                    .itemTag(0, selectArea: normalValue.selectArea0) {
                        HStack {
                            Text("Branches")
                        }
                        .font(.callout)
                        .foregroundColor(Color.white)
                    }
                Text("Tags")
                    .font(.callout)
                    .foregroundColor(Color.white.opacity(0.5))
                    .itemTag(1, selectArea: normalValue.selectArea1) {
                        HStack {
                            Text("Tags")
                        }
                        .font(.callout)
                        .foregroundColor(Color.white)
                    }
                Text("Stashes")
                    .font(.callout)
                    .foregroundColor(Color.white.opacity(0.5))
                    .itemTag(2, selectArea: normalValue.selectArea2) {
                        HStack {
                            Text("Stashes")
                        }
                        .font(.callout)
                        .foregroundColor(Color.white)
                    }
                Text("History")
                    .font(.callout)
                    .foregroundColor(Color.white.opacity(0.5))
                    .itemTag(3, selectArea: normalValue.selectArea3) {
                        HStack {
                            Text("History")
                        }
                        .font(.callout)
                        .foregroundColor(Color.white)
                    }
            }
        }, style: {
            ASNormalStyle { _ in
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(hex: 0x191919))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke()
                            .fill(Color(hex: 0x282828))
                    )
                    .padding(3.5)
            }
            .background(Color(hex: 0x0B0C10))
            .clipShape(RoundedRectangle(cornerRadius: 5))
        })
        .font(.system(size: 20))
    }

    @ViewBuilder private var contentView: some View {
        switch selection {
        case Selection.branches:
            branchesView
        case Selection.tags:
            tagsView
        case Selection.stashes:
            stashesView
        case Selection.history:
            historyView
        default:
            fatalError()
        }
    }

    private var branchesView: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.branches(for: repository)) { branch in
                BranchView(
                    branch: branch,
                    commits: viewModel.commitsForBranch(branch, in: repository),
                    isCurrentBranch: viewModel.isCurrentBranch(branch, in: repository)
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
            .padding(.bottom, 10)
        }
        .flipsForRightToLeftLayoutDirection(true)
        .environment(\.layoutDirection, .rightToLeft)
    }

    private var stashesView: some View {
        Text("Stashes")
    }

    private var historyView: some View {
        Text("History")
    }
}

@Observable class BranchSectionNormalValue {
    var constant = ASConstant(divideLine: .init(color: Color(hex: 0x444444), scale: 0))
    var selectArea0: CGFloat = 0
    var selectArea1: CGFloat = 0
    var selectArea2: CGFloat = 0
    var selectArea3: CGFloat = 0
}
