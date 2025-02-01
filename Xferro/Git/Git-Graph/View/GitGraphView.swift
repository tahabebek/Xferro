//
//  GitGraphView.swift
//  Xferro
//
//  Created by Taha Bebek on 1/30/25.
//

import SwiftUI

struct GitGraphView: View {
    @Environment(GGViewModel.self) var viewModel

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
//            GeometryReader { geometry in
                ZStack {
                    VStack {
                        Text(viewModel.gitGraph.commits.count.formatted())
                            .foregroundStyle(currentTheme.primaryText.suiColor)
                        Spacer()
                    }
                }
                .frame(minWidth: calculateMinWidth(), minHeight: calculateMinHeight())
                .border(Color.blue)
                .onAppear {
                    print("min width: \(calculateMinWidth())")
                    print("min height: \(calculateMinHeight())")
                }
//            }
//            .border(Color.red)
        }
        .background(viewModel.config.backgroundColor)
    }

    private func calculateMinWidth() -> CGFloat {
        let maxColumn = viewModel.gitGraph.allBranches.compactMap {
            print("branch: \($0.name), column: \($0.visual.column ?? -1)")
            return $0.visual.column
        }.max() ?? 0
        return CGFloat(maxColumn + 1) * viewModel.config.columnWidth
    }

    // Calculate minimum height based on number of commits
    private func calculateMinHeight() -> CGFloat {
        CGFloat(viewModel.gitGraph.commits.count) * viewModel.config.rowHeight
    }
}

#Preview(traits: .modifier(GGPreviewViewModel())) {
    GitGraphView()
    .frame(width: Dimensions.commitsViewWidth, height: Dimensions.appHeight)
}
