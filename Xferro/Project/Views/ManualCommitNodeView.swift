//
//  UTNodeView.swift
//  Xferro
//
//  Created by Taha Bebek on 1/13/25.
//


import SwiftUI

//struct ManualCommitNodeView: View {
//    @Environment(ProjectViewModel.self) var projectViewModel
//    let nodeData: ManualCommitNodeData
//
//    var body: some View {
//        Group {
//            if nodeData.commit == projectViewModel.currentCommit {
//                Circle()
//                    .fill(nodeData.selectedColor)
//                    .stroke(.yellow, lineWidth: nodeData.isMarked ? 2 : 0)
//            } else if let peekCommitOID = projectViewModel.peekCommit?.commit.oid, nodeData.oid == peekCommitOID {
//                Circle()
//                    .fill(.blue.opacity(0.5))
//                    .stroke(.yellow, lineWidth: nodeData.isMarked ? 2 : 0)
//                    .overlay { Image(systemName: "eye.circle.fill")}
//            } else {
//                Circle()
//                    .fill(nodeData.color)
//                    .stroke(.yellow, lineWidth: nodeData.isMarked ? 2 : 0)
//            }
//        }
//        .frame(width: nodeData.shape.width, height: nodeData.shape.height)
//    }
//}
