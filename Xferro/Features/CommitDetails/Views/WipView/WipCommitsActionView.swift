//
//  WipCommitsActionView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/17/25.
//

import SwiftUI

struct WipCommitsActionView: View {
    @State private var horizontalAlignment: HorizontalAlignment = .leading
    @State private var verticalAlignment: VerticalAlignment = .top

    let onBoxActionTapped: (WipCommitActionButtonsView.BoxAction) async -> Void

    var body: some View {
        VStack {
            AnyLayout(FlowLayout(alignment:.init(horizontal: horizontalAlignment, vertical: verticalAlignment))) {
                WipCommitActionButtonsView(
                    onTap: { action in
                        Task {
                            await onBoxActionTapped(action)
                        }
                    }
                )
            }
            .frame(maxWidth: .infinity)
            .animation(.default, value: horizontalAlignment)
            .animation(.default, value: verticalAlignment)
        }
    }
}
