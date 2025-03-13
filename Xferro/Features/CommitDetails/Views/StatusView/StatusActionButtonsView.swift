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
        case commitAndPush = "Commit, and Push"
        case amendAndPush = "Amend, and Push"
        case commitAndForcePush = "Commit, and Force Push"
        case amendAndForcePush = "Amend, and Force Push"
        case stash = "Stash"
        case popStash = "Pop Stash"
        case applyStash = "Apply Stash"
        case discardAll = "Discard All"
        case addCustom = "Add Custom"
    }
    
    @State private var boxActions: [BoxAction] = BoxAction.allCases
    @Binding var commitSummary: String
    @Binding var canCommit: Bool
    @Binding var hasChanges: Bool

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
            case .commitAndPush:
                disabled = commitSummary.isEmptyOrWhitespace || !hasChanges
            case .amendAndPush:
                disabled = !hasChanges
            case .commitAndForcePush:
                disabled = commitSummary.isEmptyOrWhitespace || !hasChanges
            case .amendAndForcePush:
                disabled = !hasChanges
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
