//
//  PopStashButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/18/25.
//

import SwiftUI

struct PopStashButton: View {
    let stashes: [SelectableStash]
    @Binding var errorString: String?
    
    let title: String
    let onPopStash: () async throws -> Void

    var body: some View {
        XFerroButton<Void>(
            title: title,
            info: XFerroButtonInfo(info: InfoTexts.stash),
            disabled: stashes.isEmpty,
            onTap: {
                Task {
                    do {
                        try await onPopStash()
                    } catch {
                        errorString = error.localizedDescription
                    }
                }
            }
        )
    }
}
