//
//  AddCommitButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/31/25.
//

import SwiftUI

struct AddCommitButton: View {
    @Binding var canCommit: Bool
    @Binding var hasChanges: Bool
    @Binding var commitSummary: String
    
    let title: String
    let onAddCommit: () -> Void

    var body: some View {
        XFButton<Void, Text>(
            title: title,
            info: XFButtonInfo(info: InfoTexts.commit),
            disabled: commitSummary.isEmptyOrWhitespace || canCommit || !hasChanges,
            onTap: {
                onAddCommit()
            }
        )
    }
}
