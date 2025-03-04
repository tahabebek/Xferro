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
    @State private var showProgress: Bool = false

    let commitSummaryIsEmptyOrWhitespace: Bool
    let stagedDeltaInfosIsEmpty: Bool
    let hasChanges: Bool
    let onCommitTapped: () -> Void
    let onBoxActionTapped: (StatusActionButtonsView.BoxAction) async -> Void

    var body: some View {
        Group {
            if showProgress {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    Spacer()
                }
            } else {
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
                            disabled: commitSummaryIsEmptyOrWhitespace || stagedDeltaInfosIsEmpty || !hasChanges,
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
                            stagedDeltaInfosIsEmpty: stagedDeltaInfosIsEmpty,
                            commitSummaryIsEmptyOrWhitespace: commitSummaryIsEmptyOrWhitespace,
                            onTap: { action in
                                isTextFieldFocused = false
                                showProgress = true
                                Task {
                                    await onBoxActionTapped(action)
                                    await MainActor.run {
                                        showProgress = false
                                    }
                                }
                            }
                        )
                    }
                    .animation(.default, value: horizontalAlignment)
                    .animation(.default, value: verticalAlignment)
                    .animation(.default, value: showProgress)
                }
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
}
