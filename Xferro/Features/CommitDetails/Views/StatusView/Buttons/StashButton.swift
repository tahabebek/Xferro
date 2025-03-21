//
//  StashButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/18/25.
//

import SwiftUI

struct StashButton: View {
    @Binding var hasChanges: Bool
    @Binding var errorString: String?

    let title: String
    let onStash: () async throws -> Void

    var body: some View {
        XFerroButton<Void>(
            title: title,
            info: XFerroButtonInfo(info: InfoTexts.stash),
            disabled: !hasChanges,
            onTap: {
                Task {
                    do {
                        try await onStash()
                    } catch {
                        errorString = error.localizedDescription
                    }
                }
            }
        )
    }
}
