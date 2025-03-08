//
//  StatusActionView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct StatusActionView: View {
    @Binding var commitSummary: String
    @FocusState private var isTextFieldFocused: Bool
    @State private var horizontalAlignment: HorizontalAlignment = .leading
    @State private var verticalAlignment: VerticalAlignment = .top

    let commitSummaryIsEmptyOrWhitespace: Bool
    let canCommit: Bool
    let hasChanges: Bool
    let onCommitTapped: () -> Void
    let onBoxActionTapped: (StatusActionButtonsView.BoxAction) async -> Void

    var body: some View {

        VStack {
            HStack {
                Form {
                    TextField(
                        "Summary",
                        text: $commitSummary,
                        prompt: Text("Summary for commit, amend or stash"),
                        axis: .vertical
                    )
                    .focused($isTextFieldFocused)
                    .textFieldStyle(.roundedBorder)
                }
                XFerroButton(
                    title: "Commit",
                    disabled: commitSummaryIsEmptyOrWhitespace || canCommit || !hasChanges,
                    dangerous: false,
                    isProminent: true,
                    onTap: {
                        onCommitTapped()
                        isTextFieldFocused = false
                    }
                )
            }
            .padding(.bottom, StatusView.actionBoxBottomPadding)
            AnyLayout(FlowLayout(alignment:.init(horizontal: horizontalAlignment, vertical: verticalAlignment))) {
                StatusActionButtonsView(
                    hasChanges: hasChanges,
                    canCommit: canCommit,
                    commitSummaryIsEmptyOrWhitespace: commitSummaryIsEmptyOrWhitespace,
                    onTap: { action in
                        isTextFieldFocused = false
                        Task {
                            await onBoxActionTapped(action)
                        }
                    }
                )
            }
            .animation(.default, value: horizontalAlignment)
            .animation(.default, value: verticalAlignment)
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
}
