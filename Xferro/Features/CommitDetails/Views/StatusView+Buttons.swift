//
//  StatusView+Buttons.swift
//  Xferro
//
//  Created by Taha Bebek on 2/17/25.
//

import SwiftUI

// ActionBox
extension StatusView {
    var commitButton: some View {
        buttonWith(title: "Commit", disabled: commitSummaryIsEmptyOrWhitespace || statusViewModel.stagedDeltaInfos.isEmpty) {
            guard let message = commitSummary[statusViewModel.selectableStatus.oid] else {
                fatalError(.impossible)
            }
            commitsViewModel.commitTapped(repository: statusViewModel.repository, message: message)
            commitSummary[statusViewModel.selectableStatus.oid] = nil
            isTextFieldFocused = false
        }
    }
    var amendButton: some View {
        buttonWith(title: "Amend", disabled: statusViewModel.stagedDeltaInfos.isEmpty) {
            commitsViewModel.amendTapped(
                repository: statusViewModel.repository,
                message: commitSummary[statusViewModel.selectableStatus.oid]
            )
        }
    }
    var stageAllAndCommitButton: some View {
        buttonWith(title: "Stage all + commit", disabled: commitSummaryIsEmptyOrWhitespace) {
            guard let message = commitSummary[statusViewModel.selectableStatus.oid] else {
                fatalError(.impossible)
            }
            commitsViewModel.stageAllButtonTapped(repository: statusViewModel.repository)
            commitsViewModel.commitTapped(repository: statusViewModel.repository, message: message)
            commitSummary[statusViewModel.selectableStatus.oid] = nil
            isTextFieldFocused = false
        }
    }
    var stageAllAndAmendButton: some View {
        buttonWith(title: "Stage all + amend") {
            commitsViewModel.stageAllButtonTapped(repository: statusViewModel.repository)
            commitsViewModel.amendTapped(
                repository: statusViewModel.repository,
                message: commitSummary[statusViewModel.selectableStatus.oid]
            )
            commitSummary[statusViewModel.selectableStatus.oid] = nil
            isTextFieldFocused = false
        }
    }
    var stageAllCommitAndPushButton: some View {
        buttonWith(
            title: "Stage all + commit + push",
            disabled: commitSummaryIsEmptyOrWhitespace
        ) {
            guard let message = commitSummary[statusViewModel.selectableStatus.oid] else {
                fatalError(.impossible)
            }
            commitsViewModel.stageAllButtonTapped(repository: statusViewModel.repository)
            commitsViewModel.commitTapped(repository: statusViewModel.repository, message: message)
            commitSummary[statusViewModel.selectableStatus.oid] = nil
            isTextFieldFocused = false
            fatalError(.unimplemented)
        }
    }
    var stageAllCommitAndForcePushButton: some View {
        buttonWith(
            title: "Stage all + commit + force push",
            disabled: commitSummaryIsEmptyOrWhitespace,
            dangerous: true
        ) {
            guard let message = commitSummary[statusViewModel.selectableStatus.oid] else {
                fatalError(.impossible)
            }
            commitsViewModel.stageAllButtonTapped(repository: statusViewModel.repository)
            commitsViewModel.commitTapped(repository: statusViewModel.repository, message: message)
            commitSummary[statusViewModel.selectableStatus.oid] = nil
            isTextFieldFocused = false
            fatalError(.unimplemented)
        }
    }
    var stageAllAmendAndPushButton: some View {
        buttonWith(title: "Stage all + amend + push") {
            commitsViewModel.stageAllButtonTapped(repository: statusViewModel.repository)
            commitsViewModel.amendTapped(
                repository: statusViewModel.repository,
                message: commitSummary[statusViewModel.selectableStatus.oid]
            )
            commitSummary[statusViewModel.selectableStatus.oid] = nil
            isTextFieldFocused = false
            fatalError(.unimplemented)
        }
    }
    var stageAllAmendAndForcePushButton: some View {
        buttonWith(
            title: "Stage all + amend + force push",
            dangerous: true
        ) {
            commitsViewModel.stageAllButtonTapped(repository: statusViewModel.repository)
            commitsViewModel.amendTapped(
                repository: statusViewModel.repository,
                message: commitSummary[statusViewModel.selectableStatus.oid]
            )
            commitSummary[statusViewModel.selectableStatus.oid] = nil
            isTextFieldFocused = false
            fatalError(.unimplemented)
        }
    }
    var pushStashButton: some View {
        buttonWith(title: "Push stash") {
            fatalError(.unimplemented)
        }
    }
    var popStashButton: some View {
        buttonWith(title: "Pop stash") {
            fatalError(.unimplemented)
        }
    }
    var applyStashButton: some View {
        buttonWith(title: "Apply stash") {
            fatalError(.unimplemented)
        }
    }
    var addCustomButton: some View {
        buttonWith(title: "Add your command") {
            fatalError(.unimplemented)
        }
    }
}

// Staged Files
extension StatusView {
    var unstageAllStagedButton: some View {
        buttonWith(title: "Unstage All") {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: false,
                repository: statusViewModel.repository,
                deltaInfos: statusViewModel.stagedDeltaInfos
            )
        }
    }
    func unstageSelectedStagedButton(deltaInfo: DeltaInfo) -> some View {
        Button {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: false,
                repository: statusViewModel.repository,
                deltaInfos: [deltaInfo]
            )
        } label: {
            Image(systemName: "minus")
        }
        .buttonStyle(.borderless)
    }
}

// Unstaged Files
extension StatusView {
    var stageAllUnstagedButton: some View {
        buttonWith(title: "Stage All") {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: true,
                repository: statusViewModel.repository,
                deltaInfos: statusViewModel.unstagedDeltaInfos
            )
        }
    }
    func stageSelectedUnstagedButton(deltaInfo: DeltaInfo)-> some View {
        Button {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: true,
                repository: statusViewModel.repository,
                deltaInfos: [deltaInfo]
            )
        } label: {
            Image(systemName: "plus")
        }
        .buttonStyle(.borderless)
    }
}

// Untracked Files
extension StatusView {
    var stageAllUntrackedButton: some View {
        buttonWith(title: "Stage all") {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: true,
                repository: statusViewModel.repository,
                deltaInfos: statusViewModel.untrackedDeltaInfos
            )
        }
    }

    func stageSelectedUntrackedButton(deltaInfo: DeltaInfo) -> some View {
        Button {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: true,
                repository: statusViewModel.repository,
                deltaInfos: [deltaInfo]
            )
        } label: {
            Image(systemName: "plus")
        }
        .buttonStyle(.borderless)
    }
}

// MARK: Helpers
extension StatusView {
    @ViewBuilder private func buttonWith(
        title: String,
        disabled: Bool = false,
        dangerous: Bool = false,
        action: @escaping () -> Void) -> some View {
            let disabled = disabled || !hasChanges
            let button = Button {
                action()
            } label: {
                if dangerous {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.octagon.fill")
                            .foregroundStyle(Color(nsColor: .systemRed))
                        Text(title)
                    }
                    .font(.caption)
                } else {
                    Text(title)
                        .font(.caption)
                }
            }
//                .controlSize(.small)
                .disabled(disabled)


            if disabled {
                button
                    .buttonStyle(.bordered)
            } else {
                button
                    .buttonStyle(.borderedProminent)
            }
        }

    var commitSummaryIsEmptyOrWhitespace: Bool {
        commitSummary[statusViewModel.selectableStatus.oid]?.isEmptyOrWhitespace ?? true
    }
}
