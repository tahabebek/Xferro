//
//  StatusConflictedActionView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/26/25.
//

import SwiftUI

enum ConflictType: String {
    case merge = "merge"
    case rebase = "rebase"
    case interactiveRebase = "interactive-rebase"
    case cherryPick = "cherry-pick"
    case revert = "revert"
    case bisect = "bisect"
    case squash = "squash"
}

struct StatusConflictedActionView: View {
    @State private var horizontalAlignment: HorizontalAlignment = .leading
    @State private var verticalAlignment: VerticalAlignment = .top
    let conflictType: ConflictType

    let onContinueMergeTapped: () -> Void
    let onAbortMergeTapped: () -> Void
    let onContinueRebaseTapped: () -> Void
    let onAbortRebaseTapped: () -> Void

    var body: some View {
        VStack {
            AnyLayout(FlowLayout(alignment:.init(
                horizontal: horizontalAlignment,
                vertical: verticalAlignment))) {
                switch conflictType {
                case .merge, .interactiveRebase:
                    XFButton<Void>(
                        title: "Continue Merge",
                        info: XFButtonInfo(info: InfoTexts.continueMerge),
                        onTap: {
                            onContinueMergeTapped()
                        }
                    )
                    XFButton<Void>(
                        title: "Abort Merge",
                        info: XFButtonInfo(info: InfoTexts.abortMerge),
                        onTap: {
                            onAbortMergeTapped()
                        }
                    )
                case .rebase:
                    XFButton<Void>(
                        title: "Continue Rebase",
                        info: XFButtonInfo(info: InfoTexts.continueMerge),
                        onTap: {
                            onContinueRebaseTapped()
                        }
                    )
                    XFButton<Void>(
                        title: "Abort Rebase",
                        info: XFButtonInfo(info: InfoTexts.abortMerge),
                        onTap: {
                            onAbortRebaseTapped()
                        }
                    )
                case .cherryPick:
                    fatalError(.unimplemented)
                case .revert:
                    fatalError(.unimplemented)
                case .bisect:
                    fatalError(.unimplemented)
                case .squash:
                    fatalError(.unimplemented)
                }
            }
            .animation(.default, value: horizontalAlignment)
            .animation(.default, value: verticalAlignment)
        }
    }
}
