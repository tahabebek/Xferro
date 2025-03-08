//
//  StatusActionButtonsView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct StatusActionButtonsView: View {
    enum BoxAction: String, CaseIterable, Identifiable, Equatable {
        var id: String { rawValue }
//        case splitAndCommit = "Split and Commit"
        case amend = "Amend"
        case stageAll = "Include All"
        case stageAllAndCommit = "Include All and Commit"
        case stageAllAndAmend = "Include All and Amend"
        case stageAllCommitAndPush = "Include All, Commit, and Push"
        case stageAllAmendAndPush = "Include All, Amend, and Push"
        case stageAllCommitAndForcePush = "Include All, Commit, and Force Push"
        case stageAllAmendAndForcePush = "Include All, Amend, and Force Push"
        case stash = "Stash"
        case popStash = "Pop Stash"
        case applyStash = "Apply Stash"
        case discardAll = "Discard All"
        case addCustom = "Add Custom"
    }
    
    @State private var boxActions: [BoxAction] = BoxAction.allCases

    let hasChanges: Bool
    let canCommit: Bool
    let commitSummaryIsEmptyOrWhitespace: Bool
    let onTap: (BoxAction) -> Void

    var body: some View {
        ForEach(boxActions) { boxAction in
            var disabled = false
            var dangerous = false

            switch boxAction {
//            case .splitAndCommit:
//                disabled = !hasChanges
            case .amend:
                disabled = canCommit || !hasChanges
            case .stageAll:
                disabled = !hasChanges
            case .stageAllAndCommit:
                disabled = commitSummaryIsEmptyOrWhitespace || !hasChanges
            case .stageAllAndAmend:
                disabled = !hasChanges
            case .stageAllCommitAndPush:
                disabled = commitSummaryIsEmptyOrWhitespace || !hasChanges
            case .stageAllAmendAndPush:
                disabled = !hasChanges
            case .stageAllCommitAndForcePush:
                disabled = commitSummaryIsEmptyOrWhitespace || !hasChanges
                dangerous = true
            case .stageAllAmendAndForcePush:
                disabled = !hasChanges
                dangerous = true
            case .stash:
                disabled = !hasChanges
            case .discardAll:
                disabled = !hasChanges
                dangerous = true
            case .popStash, .applyStash, .addCustom:
                break
            }
            return XFerroButton(
                title: boxAction.rawValue,
                disabled: disabled,
                dangerous: dangerous,
                isProminent: true,
                onTap: { onTap(boxAction) })
        }
        .animation(.default, value: boxActions)
    }
}
