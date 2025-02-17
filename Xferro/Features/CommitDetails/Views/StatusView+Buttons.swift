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
            commitSummary[statusViewModel.selectableStatus.oid] = ""
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
    var stageAllButton: some View {
        buttonWith(title: "Stage all", disabled: false) {
            commitsViewModel.stageAllButtonTapped(repository: statusViewModel.repository)
        }
    }
    var unstageAllButton: some View {
        buttonWith(title: "Unstage all", disabled: statusViewModel.stagedDeltaInfos.isEmpty) {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: false,
                repository: statusViewModel.repository,
                deltaInfos: statusViewModel.stagedDeltaInfos
            )
        }
    }
    var stageAllAndCommitButton: some View {
        buttonWith(title: "Stage all and commit", disabled: commitSummaryIsEmptyOrWhitespace) {
            fatalError(.unimplemented)
        }
    }
    var stageAllAndAmendButton: some View {
        buttonWith(title: "Stage all and amend", disabled: false) {
            commitsViewModel.stageAllButtonTapped(repository: statusViewModel.repository)
            commitsViewModel.amendTapped(
                repository: statusViewModel.repository,
                message: commitSummary[statusViewModel.selectableStatus.oid]
            )
        }
    }
    var stageAllCommitAndPushButton: some View {
        buttonWith(title: "Stage all, commit, and push", disabled: false) {
            fatalError(.unimplemented)
        }
    }
    var stageAllAmendAndPushButton: some View {
        buttonWith(title: "Stage all, amend, and push", disabled: !commitSummaryIsEmptyOrWhitespace) {
            fatalError(.unimplemented)
        }
    }
    var pushStashButton: some View {
        buttonWith(title: "Push stash", disabled: false) {
            fatalError(.unimplemented)
        }
    }
    var popStashButton: some View {
        buttonWith(title: "Pop stash", disabled: false) {
            fatalError(.unimplemented)
        }
    }
    var applyStashButton: some View {
        buttonWith(title: "Apply stash", disabled: false) {
            fatalError(.unimplemented)
        }
    }
    var addCustomButton: some View {
        buttonWith(title: "Add your custom command button here", disabled: false) {
            fatalError(.unimplemented)
        }
    }
}

// Staged Files
extension StatusView {
    var unstageAllStagedButton: some View {
        buttonWith(title: "Unstage All", disabled: false) {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: false,
                repository: statusViewModel.repository,
                deltaInfos: statusViewModel.stagedDeltaInfos
            )
        }
    }
    var unstageSelectedStagedButton: some View {
        buttonWith(title: "Unstage Selected", disabled: selectedStagedIds.isEmpty(key: statusViewModel.selectableStatus.oid)) {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: false,
                repository: statusViewModel.repository,
                deltaInfos: selectedStagedIds.values
                    .flatMap { $0 }
                    .compactMap { deltaInfo in
                        deltaInfo.repository == statusViewModel.repository ? deltaInfo : nil
                    }
            )
        }
    }
}

// Unstaged Files
extension StatusView {
    var stageAllUnstagedButton: some View {
        buttonWith(title: "Stage All", disabled: false) {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: true,
                repository: statusViewModel.repository,
                deltaInfos: statusViewModel.unstagedDeltaInfos
            )
        }
    }
    var stageSelectedUnstagedButton: some View {
        buttonWith(title: "Stage Selected", disabled: selectedUnstagedIds.isEmpty(key: statusViewModel.selectableStatus.oid)) {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: true,
                repository: statusViewModel.repository,
                deltaInfos: selectedUnstagedIds.values
                    .flatMap { $0 }
                    .compactMap { deltaInfo in
                        deltaInfo.repository == statusViewModel.repository ? deltaInfo : nil
                    }
            )
        }
    }
}

// Untracked Files
extension StatusView {
    var stageAllUntrackedButton: some View {
        buttonWith(title: "Stage all", disabled: false) {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: true,
                repository: statusViewModel.repository,
                deltaInfos: statusViewModel.untrackedDeltaInfos
            )
        }
    }

    var stageSelectedUntrackedButton: some View {
        buttonWith(title: "Stage Selected", disabled: selectedUntrackedIds.isEmpty(key: statusViewModel.selectableStatus.oid)) {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: true,
                repository: statusViewModel.repository,
                deltaInfos: selectedUntrackedIds.values
                    .flatMap { $0 }
                    .compactMap { deltaInfo in
                        deltaInfo.repository == statusViewModel.repository ? deltaInfo : nil
                    }
            )
        }
    }
}

// MARK: Helpers
extension StatusView {
    @ViewBuilder private func buttonWith(title: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        let button = Button {
            action()
        } label: {
            Text(title)
                .font(.caption)
        }
        .controlSize(.small)
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
