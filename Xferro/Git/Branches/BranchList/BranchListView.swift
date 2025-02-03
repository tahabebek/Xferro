//
//  BranchListView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import SwiftUI

struct RepoHeaderView: View {
    var text: String
    var body: some View {
        HStack {
            Spacer()
            Text(text)
                .padding()
                .font(.headline)
                .foregroundColor(currentTheme.primaryText.suiColor)
            Spacer()
        }
        .background(currentTheme.lightPrimary.suiColor)
    }
}

struct BranchListView: View {
    @State var viewModel: BranchListViewModel
    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(viewModel.repositories) { repository in
                            BranchSectionView(viewModel: viewModel, repository: repository)
                                .frame(width: geometry.size.width)
                        }
                        AddRepositoryButton(viewModel: viewModel)
                        Spacer()
                    }
                    .frame(width: geometry.size.width)
                    .frame(maxHeight: geometry.size.height / 2.0)
                }
                .frame(width: geometry.size.width, height: geometry.size.height / 2.0)
            }
            Spacer()
        }
    }
}

struct BranchSectionView: View {
    @State var viewModel: BranchListViewModel
    let repository: Repository
    var body: some View {
        CollapsibleSection(title: "Repository: " + (repository.gitDir?.deletingLastPathComponent().lastPathComponent ?? "Unkown Repository")) {
            ForEach(viewModel.branches(for: repository)) { branch in
                ZStack {
                    BranchView(
                        branch: branch,
                        commits: viewModel.commitsForBranch(branch, in: repository),
                        isCurrentBranch: viewModel.isCurrentBranch(branch, in: repository)
                    )
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct AddRepositoryButton: View {
    @State var viewModel: BranchListViewModel
    var body: some View {
        HStack {
            Spacer()
            Button {
                viewModel.addRepositoryButtonTapped()
            } label: {
                Text("Add repository")
            }
            .padding()
            Spacer()
        }
    }
}

struct BranchView: View {
    let branch: Branch
    let commits: [Commit]
    let isCurrentBranch : Bool

    var header: String {
        if isCurrentBranch {
            "Current branch: "
        } else {
            ""
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Text(header + branch.name)
                    .padding(2)
                    .background(isCurrentBranch ? Color.orange.opacity(0.3) : Color.gray.opacity(0.3))
                    .cornerRadius(4)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                CirclesWithArrows(numberOfCircles: commits.count) { index in
                    Circle()
                        .fill(!isCurrentBranch ? .gray : index == 0 ? .red : .gray)
                        .frame(width: 36, height: 36)
                        .overlay {
                            Text(commits[index].oid.debugOID.prefix(4))
                                .font(.footnote)
                                .foregroundColor(.white)
                                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        }
                }
            }
            .padding(.horizontal)
        }
        .flipsForRightToLeftLayoutDirection(true)
        .environment(\.layoutDirection, .rightToLeft)
    }
}

struct CirclesWithArrows<CircleContent: View>: View {
    let numberOfCircles: Int
    let circleContent: (Int) -> CircleContent
    let circleSize: CGFloat
    let spacing: CGFloat

    // Derived constants
    private var arrowY: CGFloat { circleSize / 2 }
    private var arrowHeadSize: CGFloat { circleSize / 4.5 }  // Scaled with circle size
    private let lineWidth: CGFloat = 1

    init(
        numberOfCircles: Int,
        circleSize: CGFloat = 36,
        spacing: CGFloat = 72,
        @ViewBuilder circleContent: @escaping (Int) -> CircleContent
    ) {
        self.numberOfCircles = numberOfCircles
        self.circleSize = circleSize
        self.spacing = spacing
        self.circleContent = circleContent
    }

    var body: some View {
        HStack {
            ZStack {
                // Draw the arrows
                ForEach(0..<(numberOfCircles-1), id: \.self) { index in
                    // Arrow line
                    Path { path in
                        let startX = CGFloat(index) * spacing + circleSize
                        let endX = CGFloat(index + 1) * spacing

                        path.move(to: CGPoint(x: startX, y: arrowY))
                        path.addLine(to: CGPoint(x: endX, y: arrowY))
                    }
                    .stroke(.gray, lineWidth: lineWidth)

                    // Arrow head
                    Path { path in
                        let arrowX = CGFloat(index + 1) * spacing

                        path.move(to: CGPoint(x: arrowX, y: arrowY))
                        path.addLine(to: CGPoint(x: arrowX - arrowHeadSize, y: arrowY - arrowHeadSize))
                        path.addLine(to: CGPoint(x: arrowX - arrowHeadSize, y: arrowY + arrowHeadSize))
                        path.closeSubpath()
                    }
                    .fill(Color.gray)
                }
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))

                // Draw the circles
                HStack(spacing: spacing - circleSize) {
                    ForEach(0..<numberOfCircles, id: \.self) { index in
                        circleContent(index)
                            .frame(width: circleSize, height: circleSize)
                    }
                }
            }
        }
    }
}

struct CollapsibleSection<Content: View>: View {
    @State private var isCollapsed = false
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(action: {
                withAnimation(.easeInOut) {
                    isCollapsed.toggle()
                }
            }) {
                HStack {
                    Text(title)
                    Spacer()
                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
            }

            if !isCollapsed {
                content
                Divider()
            }
        }
    }
}
