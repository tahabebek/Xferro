//
//  StatusActionButtonsView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct StatusActionButtonsView: View {
    @Environment(StatusViewModel.self) var statusViewModel
    enum BoxAction: String, CaseIterable, Identifiable, Equatable {
        var id: String { rawValue }
        case amend = "Amend"
        case commitAndPush = "Commit and Push"
        case amendAndPush = "Amend and Push"
        case commitAndForcePush = "Commit and Force Push with Lease"
        case amendAndForcePush = "Amend and Force Push with Lease"
        case stash = "Push Stash"
        case popStash = "Pop Stash"
//        case applyStash = "Apply Stash"
        case discardAll = "Discard All Changes"
    }
    
    @State private var boxActions: [BoxAction] = BoxAction.allCases
    @Binding var commitSummary: String
    @Binding var canCommit: Bool
    @Binding var hasChanges: Bool
    let remotes: [Remote]
    let stashes: [SelectableStash]
    @Binding var errorString: String?
    @State var selectedRemoteForPush: Remote?
    @State var selectedStashToApply: SelectableStash?

    var body: some View {
        ForEach(boxActions) { boxAction in
            switch boxAction {
            case .amend:
                AmendButton(
                    canCommit: $canCommit,
                    hasChanges: $hasChanges,
                    errorString: $errorString,
                    title: boxAction.rawValue
                )
            case .commitAndPush:
                PushButton(
                    commitSummary: $commitSummary,
                    canCommit: $canCommit,
                    hasChanges: $hasChanges,
                    selectedRemoteForPush: $selectedRemoteForPush,
                    errorString: $errorString,
                    remotes: remotes,
                    title: boxAction.rawValue,
                    amend: false,
                    force: false
                )
            case .amendAndPush:
                PushButton(
                    commitSummary: $commitSummary,
                    canCommit: $canCommit,
                    hasChanges: $hasChanges,
                    selectedRemoteForPush: $selectedRemoteForPush,
                    errorString: $errorString,
                    remotes: remotes,
                    title: boxAction.rawValue,
                    amend: true,
                    force: false
                )
            case .commitAndForcePush:
                PushButton(
                    commitSummary: $commitSummary,
                    canCommit: $canCommit,
                    hasChanges: $hasChanges,
                    selectedRemoteForPush: $selectedRemoteForPush,
                    errorString: $errorString,
                    remotes: remotes,
                    title: boxAction.rawValue,
                    amend: false,
                    force: true
                )
            case .amendAndForcePush:
                PushButton(
                    commitSummary: $commitSummary,
                    canCommit: $canCommit,
                    hasChanges: $hasChanges,
                    selectedRemoteForPush: $selectedRemoteForPush,
                    errorString: $errorString,
                    remotes: remotes,
                    title: boxAction.rawValue,
                    amend: true,
                    force: true
                )
            case .stash:
                StashButton(
                    hasChanges: $hasChanges,
                    errorString: $errorString,
                    title: boxAction.rawValue
                )
            case .popStash:
                PopStashButton(
                    stashes: stashes,
                    errorString: $errorString,
                    title: boxAction.rawValue
                )
//            case .applyStash:
//                ApplyStashButton(
//                    selectedStashToApply: $selectedStashToApply,
//                    errorString: $errorString,
//                    title: boxAction.rawValue,
//                    stashes: stashes
//                )
            case .discardAll:
                DiscardAllButton(
                    hasChanges: $hasChanges,
                    errorString: $errorString,
                    title: boxAction.rawValue
                )
            }
        }
        .animation(.default, value: boxActions)
    }
}
