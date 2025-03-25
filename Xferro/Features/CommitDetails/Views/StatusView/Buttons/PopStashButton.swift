//
//  PopStashButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/18/25.
//

import SwiftUI

struct PopStashButton: View {
    let stashes: [SelectableStash]
    
    let title: String
    let onPopStash: () -> Void

    var body: some View {
        XFButton<Void>(
            title: title,
            info: XFButtonInfo(info: InfoTexts.stash),
            disabled: stashes.isEmpty,
            onTap: {
                onPopStash()
            }
        )
    }
}
