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
    @Binding var errorString: String?

    let title: String
    let onAmend: () async throws -> Void

    var body: some View {
        XFerroButton<Void>(
            title: title,
            info: XFerroButtonInfo(info: InfoTexts.amend),
            disabled: canCommit || !hasChanges,
            onTap: {
                Task {
                    do {
                        try await onAmend()
                    } catch {
                        errorString = error.localizedDescription
                    }
                }
            }
        )
    }
}
