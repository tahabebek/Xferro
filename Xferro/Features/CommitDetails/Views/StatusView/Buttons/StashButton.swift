//
//  StashButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/18/25.
//

import SwiftUI

struct StashButton: View {
    @Binding var hasChanges: Bool

    let title: String
    let onStash: () -> Void

    var body: some View {
        XFButton<Void>(
            title: title,
            info: XFButtonInfo(info: InfoTexts.stash),
            disabled: !hasChanges,
            onTap: {
                onStash()
            }
        )
    }
}
