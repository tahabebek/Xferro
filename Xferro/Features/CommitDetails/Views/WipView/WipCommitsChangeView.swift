//
//  WipCommitsChangeView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/17/25.
//

import SwiftUI

struct WipCommitsChangeView: View {
    @Binding var currentFile: OldNewFile?
    @Binding var files: [OldNewFile]
    var body: some View {
        ZStack {
            Color(hexValue: 0x15151A)
                .cornerRadius(8)
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 4) {
                    if files.isNotEmpty {
                        WipCommitsFileView(
                            currentFile: $currentFile,
                            files: $files
                        )
                    }
                }
            }
            .padding(.bottom)
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
}

