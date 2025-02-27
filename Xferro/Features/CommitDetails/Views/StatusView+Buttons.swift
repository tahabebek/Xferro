//
//  StatusView+Buttons.swift
//  Xferro
//
//  Created by Taha Bebek on 2/17/25.
//

import SwiftUI

// ActionBox
extension StatusView {
    func commitButton(_ title: String) -> some View {
        AnyView.buttonWith(
            title: title,
            disabled: commitSummaryIsEmptyOrWhitespace || statusViewModel.stagedDeltaInfos.isEmpty || !hasChanges) {
            guard let message = commitSummary[statusViewModel.selectableStatus.oid] else {
                fatalError(.impossible)
            }
            commitsViewModel.commitTapped(repository: statusViewModel.repository, message: message)
            commitSummary[statusViewModel.selectableStatus.oid] = nil
            isTextFieldFocused = false
        }
    }
    func splitAndCommitButton(_ title: String) -> some View {
        AnyView.buttonWith(
            title: title,
            disabled: !hasChanges) {
                guard let message = commitSummary[statusViewModel.selectableStatus.oid] else {
                    fatalError(.impossible)
                }
                commitsViewModel.commitTapped(repository: statusViewModel.repository, message: message)
                commitSummary[statusViewModel.selectableStatus.oid] = nil
                isTextFieldFocused = false
            }
    }
    func amendButton(_ title: String) -> some View {
        AnyView.buttonWith(title: title, disabled: statusViewModel.stagedDeltaInfos.isEmpty || !hasChanges) {
            commitsViewModel.amendTapped(
                repository: statusViewModel.repository,
                message: commitSummary[statusViewModel.selectableStatus.oid]
            )
        }
    }
    func stageAllAndCommitButton(_ title: String) -> some View {
        AnyView.buttonWith(title: title, disabled: commitSummaryIsEmptyOrWhitespace || !hasChanges) {
            guard let message = commitSummary[statusViewModel.selectableStatus.oid] else {
                fatalError(.impossible)
            }
            commitsViewModel.stageAllButtonTapped(repository: statusViewModel.repository)
            commitsViewModel.commitTapped(repository: statusViewModel.repository, message: message)
            commitSummary[statusViewModel.selectableStatus.oid] = nil
            isTextFieldFocused = false
        }
    }
    func stageAllAndAmendButton(_ title: String) -> some View {
        AnyView.buttonWith(title: title, disabled: !hasChanges) {
            commitsViewModel.stageAllButtonTapped(repository: statusViewModel.repository)
            commitsViewModel.amendTapped(
                repository: statusViewModel.repository,
                message: commitSummary[statusViewModel.selectableStatus.oid]
            )
            commitSummary[statusViewModel.selectableStatus.oid] = nil
            isTextFieldFocused = false
        }
    }
    func stageAllCommitAndPushButton(_ title: String) -> some View {
        AnyView.buttonWith(
            title: title,
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
    func stageAllCommitAndForcePushButton(_ title: String) -> some View {
        AnyView.buttonWith(
            title: title,
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
    func stageAllAmendAndPushButton(_ title: String) -> some View {
        AnyView.buttonWith(title: title, disabled: !hasChanges) {
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
    func stageAllAmendAndForcePushButton(_ title: String) -> some View {
        AnyView.buttonWith(
            title: title,
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
    func pushStashButton(_ title: String) -> some View {
        AnyView.buttonWith(title: title, disabled: !hasChanges) {
            fatalError(.unimplemented)
        }
    }
    func popStashButton(_ title: String) -> some View {
        AnyView.buttonWith(title: title, disabled: !hasChanges) {
            fatalError(.unimplemented)
        }
    }
    func applyStashButton(_ title: String) -> some View {
        AnyView.buttonWith(title: title, disabled: !hasChanges) {
            fatalError(.unimplemented)
        }
    }
    func addCustomButton(_ title: String) -> some View {
        AnyView.buttonWith(title: title, disabled: !hasChanges) {
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
