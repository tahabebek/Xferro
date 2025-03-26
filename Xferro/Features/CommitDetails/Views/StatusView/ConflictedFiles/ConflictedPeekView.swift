//
//  ConflictedPeekView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/26/25.
//

import SwiftUI

struct ConflictedPeekView: View {
    let file: OldNewFile
    let text: String

    var body: some View {
        Group {
            ScrollView {
                VStack(spacing: 0) {
                    PeekViewHeader(statusFileName: file.statusFileName, countString: "Conflicted")
                        .padding(.horizontal, 8)
                    Divider()
                    ZStack {
                        ScrollView {
                            Text(text)
                                .padding()
                                .font(.diff)
                        }
                        ProgressView()
                            .controlSize(.small)
                            .padding()
                            .opacity(file.diffInfo == nil ? 1 : 0)
                    }
                }
                .background(Color.clear)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .shadow(
                    color: Color.black.opacity(0.3),
                    radius: 5,
                    x: 0,
                    y: 3
                )
            }
        }
    }
}

