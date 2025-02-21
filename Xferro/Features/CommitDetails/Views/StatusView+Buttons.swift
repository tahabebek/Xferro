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
        AnyView.buttonWith(
            title: "Commit",
            disabled: commitSummaryIsEmptyOrWhitespace || statusViewModel.stagedDeltaInfos.isEmpty || !hasChanges) {
            guard let message = commitSummary[statusViewModel.selectableStatus.oid] else {
                fatalError(.impossible)
            }
            commitsViewModel.commitTapped(repository: statusViewModel.repository, message: message)
            commitSummary[statusViewModel.selectableStatus.oid] = nil
            isTextFieldFocused = false
        }
    }
    var amendButton: some View {
        AnyView.buttonWith(title: "Amend", disabled: statusViewModel.stagedDeltaInfos.isEmpty || !hasChanges) {
            commitsViewModel.amendTapped(
                repository: statusViewModel.repository,
                message: commitSummary[statusViewModel.selectableStatus.oid]
            )
        }
    }
    var stageAllAndCommitButton: some View {
        AnyView.buttonWith(title: "Stage all + commit", disabled: commitSummaryIsEmptyOrWhitespace || !hasChanges) {
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
        AnyView.buttonWith(title: "Stage all + amend", disabled: !hasChanges) {
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
        AnyView.buttonWith(
            title: "Stage all + commit + push",
            disabled: commitSummaryIsEmptyOrWhitespace || !hasChanges
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
        AnyView.buttonWith(
            title: "Stage all + commit + force push",
            disabled: commitSummaryIsEmptyOrWhitespace || !hasChanges,
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
        AnyView.buttonWith(title: "Stage all + amend + push", disabled: !hasChanges) {
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
        AnyView.buttonWith(
            title: "Stage all + amend + force push",
            disabled: !hasChanges,
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
        AnyView.buttonWith(title: "Push stash", disabled: !hasChanges) {
            fatalError(.unimplemented)
        }
    }
    var popStashButton: some View {
        AnyView.buttonWith(title: "Pop stash", disabled: !hasChanges) {
            fatalError(.unimplemented)
        }
    }
    var applyStashButton: some View {
        AnyView.buttonWith(title: "Apply stash", disabled: !hasChanges) {
            fatalError(.unimplemented)
        }
    }
    var addCustomButton: some View {
        AnyView.buttonWith(title: "Add your command", disabled: !hasChanges) {
            fatalError(.unimplemented)
        }
    }
}

// All files
extension StatusView {
    func discardSelectedButton(deltaInfo: DeltaInfo) -> some View {
        AnyView.buttonWith(title: "Discard", dangerous: true, isProminent: false, isSmall: true) {
            discardDeltaInfo = deltaInfo
        }
    }
}

// Staged Files
extension StatusView {
    var unstageAllStagedButton: some View {
        AnyView.buttonWith(title: "Unstage All") {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: false,
                repository: statusViewModel.repository,
                deltaInfos: statusViewModel.stagedDeltaInfos
            )
        }
    }
    func unstageSelectedStagedButton(deltaInfo: DeltaInfo) -> some View {
        AnyView.buttonWith(title: "Unstage", isProminent: false, isSmall: true) {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: false,
                repository: statusViewModel.repository,
                deltaInfos: [deltaInfo]
            )
        }
    }
}

// Unstaged Files
extension StatusView {
    var stageAllUnstagedButton: some View {
        AnyView.buttonWith(title: "Stage All") {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: true,
                repository: statusViewModel.repository,
                deltaInfos: statusViewModel.unstagedDeltaInfos
            )
        }
    }
    func stageSelectedUnstagedButton(deltaInfo: DeltaInfo)-> some View {
        AnyView.buttonWith(title: "Stage", isProminent: false, isSmall: true) {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: true,
                repository: statusViewModel.repository,
                deltaInfos: [deltaInfo]
            )
        }
    }
}

// Untracked Files
extension StatusView {
    var stageAllUntrackedButton: some View {
        AnyView.buttonWith(title: "Track all") {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: true,
                repository: statusViewModel.repository,
                deltaInfos: statusViewModel.untrackedDeltaInfos
            )
        }
    }

    func stageSelectedUntrackedButton(deltaInfo: DeltaInfo) -> some View {
        AnyView.buttonWith(title: "Track", isProminent: false, isSmall: true) {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: true,
                repository: statusViewModel.repository,
                deltaInfos: [deltaInfo]
            )
        }
    }

    func ignoreSelectedUntrackedButton(deltaInfo: DeltaInfo) -> some View {
        AnyView.buttonWith(title: "Ignore", isProminent: false, isSmall: true) {
            commitsViewModel.ignoreButtonTapped(
                repository: statusViewModel.repository,
                deltaInfo: deltaInfo
            )
        }
    }
}

// MARK: Helpers
extension StatusView {
    var commitSummaryIsEmptyOrWhitespace: Bool {
        commitSummary[statusViewModel.selectableStatus.oid]?.isEmptyOrWhitespace ?? true
    }
}
