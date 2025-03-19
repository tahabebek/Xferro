//
//  StashButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/18/25.
//

import SwiftUI

struct StashButton: View {
    @Environment(StatusViewModel.self) var statusViewModel
    @Binding var hasChanges: Bool
    @Binding var errorString: String?

    let title: String

    var body: some View {
        XFerroButton<Void>(
            title: title,
            disabled: !hasChanges,
            onTap: {
                Task {
                    do {
                        try await statusViewModel.onStash()
                    } catch {
                        errorString = error.localizedDescription
                    }
                }
            }
        )
    }
}
