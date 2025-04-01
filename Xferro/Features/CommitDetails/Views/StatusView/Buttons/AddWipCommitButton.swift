//
//  AddWipCommitButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/31/25.
//

import SwiftUI

struct AddWipCommitButton: View {
    @Binding var canCommit: Bool
    @Binding var hasChanges: Bool
    @Binding var commitSummary: String
    
    let title: String
    let onAddWipCommit: (String) -> Void

    var body: some View {
        XFButton<Void,Text>(
            title: title,
            info: XFButtonInfo(info: InfoTexts.wip),
            disabled: commitSummary.isEmptyOrWhitespace || canCommit || !hasChanges,
            onTap: {
                onAddWipCommit(commitSummary)
            }
        )
    }
}

