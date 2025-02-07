//
//  WIPCommitsView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

struct WIPCommitsView: View {
    @Environment(CommitsViewModel.self) var viewModel
    let columns = [
        GridItem(.adaptive(minimum: 16, maximum: 16))
    ]
    let width: CGFloat
    
    var body: some View {
        PinnedScrollableView(showsIndicators: false) {
            AutoCommitHeaderView()
        } content: {
            Group {
                VStack(spacing: 0) {
                    HStack {
                        Label("For commit", systemImage: "dot.square")
                        Spacer()
                    }
                    .frame(height: 36)
                    LazyVGrid(columns: columns) {
                        ForEach(0..<1000) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.blue)
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Text("\(index)")
                                        .foregroundColor(.white)
                                        .font(.system(size: 8))
                                )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(
                Color(hex: 0x15151A)
                    .cornerRadius(8)
            )
        }
    }

//        PinnedScrollableView(title: "AutoWIP Commits", showsIndicators: false) {
//            LazyHGrid(rows: rows, alignment: .top, spacing: 1) {
//                ForEach((0...79), id: \.self) { _ in
//                    FlaredRounded {
//                        EmptyView()
//                    }
//                    .frame(width: 8, height: 8)
//                }
//                .padding(.vertical, 1)
//            }
//            .padding(.horizontal, 1)
//            .frame(width: width)
//            .fixedSize()
//        }
//    }
}
