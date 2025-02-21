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
        buttonWith(title: "Unstage", isProminent: false, isSmall: true) {
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
        buttonWith(title: "Stage All") {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: true,
                repository: statusViewModel.repository,
                deltaInfos: statusViewModel.unstagedDeltaInfos
            )
        }
    }
    func stageSelectedUnstagedButton(deltaInfo: DeltaInfo)-> some View {
        buttonWith(title: "Stage", isProminent: false, isSmall: true) {
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
        buttonWith(title: "Track all") {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: true,
                repository: statusViewModel.repository,
                deltaInfos: statusViewModel.untrackedDeltaInfos
            )
        }
    }

    func stageSelectedUntrackedButton(deltaInfo: DeltaInfo) -> some View {
        buttonWith(title: "Track", isProminent: false, isSmall: true) {
            commitsViewModel.stageOrUnstageButtonTapped(
                stage: true,
                repository: statusViewModel.repository,
                deltaInfos: [deltaInfo]
            )
        }
    }

    func ignoreSelectedUntrackedButton(deltaInfo: DeltaInfo) -> some View {
        buttonWith(title: "Ignore", isProminent: false, isSmall: true) {
            commitsViewModel.ignoreButtonTapped(
                repository: statusViewModel.repository,
                deltaInfo: deltaInfo
            )
        }
    }
}

// MARK: Helpers
extension StatusView {
    @ViewBuilder private func buttonWith(
        title: String,
        disabled: Bool = false,
        dangerous: Bool = false,
        isProminent: Bool = true,
        isSmall: Bool = false,
        action: @escaping () -> Void) -> some View {
            let isDisabled = disabled || !hasChanges
            Button {
                action()
            } label: {
                Group {
                    if dangerous {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.octagon.fill")
                                .foregroundStyle(Color(nsColor: .systemRed))
                            Text(title)
                        }
                    } else {
                        Text(title)
                    }
                }
            }
            .disabled(isDisabled)
            .style(isDisabled: isDisabled, isProminent: isProminent, isSmall: isSmall)
        }

    var commitSummaryIsEmptyOrWhitespace: Bool {
        commitSummary[statusViewModel.selectableStatus.oid]?.isEmptyOrWhitespace ?? true
    }
}

struct XferroButtonStyle: ButtonStyle {
    let foregroundColor: Color
    let regularBackgroundColor: Color
    let prominentBackgroundColor: Color
    let pressedOpacity: CGFloat
    let disabledOpacity: CGFloat
    let isDisabled: Bool
    let isProminent: Bool
    let isSmall: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(isSmall ? .caption : .callout)
            .padding(.vertical, isSmall ? 2 : 3)
            .padding(.horizontal, isSmall ? 4 : 6)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isProminent ? prominentBackgroundColor : regularBackgroundColor)
            )
            .foregroundColor(foregroundColor)
            .opacity(configuration.isPressed ? pressedOpacity : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
            .overlay {
                if isDisabled {
                    Color.black.opacity(disabledOpacity)
                }
            }
    }
}

extension View {
    func style(
        foregroundColor: Color = .white,
        regularBackgroundColor: Color = .gray.opacity(0.4),
        prominentBackgroundColor: Color = .accentColor.opacity(0.7),
        pressedOpacity: CGFloat = 0.8,
        disabledOpacity: CGFloat = 0.6,
        isDisabled: Bool = false,
        isProminent: Bool = true,
        isSmall: Bool = false
    ) -> some View {
        self.buttonStyle(XferroButtonStyle(
            foregroundColor: foregroundColor,
            regularBackgroundColor: regularBackgroundColor,
            prominentBackgroundColor: prominentBackgroundColor,
            pressedOpacity: pressedOpacity,
            disabledOpacity: disabledOpacity,
            isDisabled: isDisabled,
            isProminent: isProminent,
            isSmall: isSmall
        ))
    }
}
