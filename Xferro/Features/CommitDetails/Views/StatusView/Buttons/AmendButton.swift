//
//  AmendButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/18/25.
//

import SwiftUI

struct AmendButton: View {
    @Binding var canCommit: Bool
    @Binding var hasChanges: Bool

    let title: String
    let onAmend: () -> Void

    var body: some View {
        XFButton<Void,Text>(
            title: title,
            info: XFButtonInfo(info: InfoTexts.amend),
            disabled: canCommit || !hasChanges,
            onTap: {
                onAmend()
            }
        )
    }
}
