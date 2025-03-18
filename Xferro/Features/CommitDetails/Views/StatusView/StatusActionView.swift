//
//  StatusActionView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct StatusActionView: View {
    @Environment(StatusViewModel.self) var statusViewModel

    @FocusState private var isTextFieldFocused: Bool
    @Binding var commitSummary: String
    @Binding var canCommit: Bool
    @Binding var hasChanges: Bool
    let remotes: [Remote]
    let stashes: [SelectableStash]
    @State private var horizontalAlignment: HorizontalAlignment = .leading
    @State private var verticalAlignment: VerticalAlignment = .top
    let onCommitTapped: () async throws -> Void
    @State var errorString: String?

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
                XFerroButton<Void>(
                    title: "Commit",
                    disabled: commitSummary.isEmptyOrWhitespace || canCommit || !hasChanges,
                    dangerous: false,
                    isProminent: true,
                    onTap: {
                        Task {
                            try await onCommitTapped()
                            isTextFieldFocused = false
                        }
                    }
                )
            }
            .padding(.bottom, Dimensions.actionBoxBottomPadding)
            AnyLayout(FlowLayout(alignment:.init(horizontal: horizontalAlignment, vertical: verticalAlignment))) {
                StatusActionButtonsView(
                    commitSummary: $commitSummary,
                    canCommit: $canCommit,
                    hasChanges: $hasChanges,
                    remotes: remotes,
                    stashes: stashes,
                    errorString: $errorString
                )
            }
            .animation(.default, value: horizontalAlignment)
            .animation(.default, value: verticalAlignment)
        }
        .onAppear {
            isTextFieldFocused = true
        }
        .alert("Error", isPresented: .init(
            get: { errorString != nil },
            set: { if !$0 { errorString = nil } }
        )) {
            Button("OK") {
                errorString = nil
            }
        } message: {
            if let message = errorString {
                Text(message)
            }
        }
    }
}
