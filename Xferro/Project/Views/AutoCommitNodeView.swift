//
//  AutoCommitNodeView.swift
//  Xferro
//
//  Created by Taha Bebek on 1/14/25.
//

import SwiftUI

//struct AutoCommitNodeView: View {
//    let nodeData: AutoCommitNodeData
//    let onTap: (AnyCommit) -> Void
//
//    func calculateColumns(for itemCount: Int) -> [GridItem] {
//        let columnCount = Int(sqrt(Double(itemCount)).rounded(.up))
//        return Array(repeating: GridItem(.flexible(), spacing: 16), count: columnCount)
//    }
//
//
//    var body: some View {
//        LazyVGrid(columns: calculateColumns(for: nodeData.commits.count), spacing: 2) {
//            ForEach(nodeData.commits, id: \.self) { commit in
//                AutoCommitView(
//                    commit: commit,
//                    color: nodeData.color,
//                    selectedColor: nodeData.selectedColor,
//                    shape: nodeData.shape
//                )
//                .onTapGesture {
//                    onTap(commit)
//                }
//            }
//        }
//        .padding()
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//
//    }
//}
