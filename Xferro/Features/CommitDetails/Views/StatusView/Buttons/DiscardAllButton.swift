//
//  DiscardAllButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/18/25.
//

import SwiftUI

struct DiscardAllButton: View {
    @Binding var hasChanges: Bool
    @Binding var errorString: String?

    let title: String
    let onDiscardAll: () async throws -> Void

    var body: some View {
        XFButton<Void>(
            title: title,
            disabled: !hasChanges,
            onTap: {
                Task {
                    do {
                        try await onDiscardAll()
                    } catch {
                        errorString = error.localizedDescription
                    }
                }
            }
        )
    }
}
