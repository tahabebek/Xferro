//
//  AutoCommitView.swift
//  Xferro
//
//  Created by Taha Bebek on 1/14/25.
//

import SwiftUI

//struct AutoCommitView: View {
//    @Environment(ProjectViewModel.self) var projectViewModel
//    @State private var rotation: Double = 0
//    let commit: AnyCommit
//    let color: Color
//    let selectedColor: Color
//    let shape: TreeNodeShape
//
//    var body: some View {
//        Group {
//            if commit == projectViewModel.currentCommit {
//                RoundedRectangle(cornerRadius: 2)
//                    .fill(selectedColor)
//                    .stroke(.yellow, lineWidth: commit.isMarked ? 2 : 0)
//            }
//            else if let peekCommitOID = projectViewModel.peekCommit?.commit.oid, commit.oid == peekCommitOID {
//                RoundedRectangle(cornerRadius: 2)
//                    .fill(color)
//                    .strokeBorder(
//                        style: StrokeStyle(
//                            lineWidth: 2,
//                            dash: [3, 2]
//                        )
//                    )
//                    .rotationEffect(.degrees(rotation))
//                    .onAppear {
//                        withAnimation(
//                            .linear(duration: 3)
//                            .repeatForever(autoreverses: false)
//                        ) {
//                            rotation = 360
//                        }
//                    }
//            }
//            else {
//                RoundedRectangle(cornerRadius: 2)
//                    .fill(color)
//                    .stroke(.yellow, lineWidth: commit.isMarked ? 2 : 0)
//            }
//        }
//        .frame(width: shape.width, height: shape.height)
//    }
//}
