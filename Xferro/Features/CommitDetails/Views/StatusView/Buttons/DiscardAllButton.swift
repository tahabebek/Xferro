//
//  DiscardAllButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/18/25.
//

import SwiftUI

struct DiscardAllButton: View {
    @Environment(StatusViewModel.self) var statusViewModel
    @Binding var hasChanges: Bool
    @Binding var errorString: String?

    let title: String

    var body: some View {
        XFerroButton<Void>(
            title: title,
            disabled: !hasChanges,
            dangerous: true,
            onTap: {
                Task {
                    do {
                        try await statusViewModel.discardAllTapped()
                    } catch {
                        errorString = error.localizedDescription
                    }
                }
            }
        )
    }
}
