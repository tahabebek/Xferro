//
//  AmendButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/18/25.
//

import SwiftUI

struct AmendButton: View {
    @Environment(StatusViewModel.self) var statusViewModel
    @Binding var canCommit: Bool
    @Binding var hasChanges: Bool
    @Binding var errorString: String?

    let title: String
    
    var body: some View {
        XFerroButton<Void>(
            title: title,
            disabled: canCommit || !hasChanges,
            onTap: {
                Task {
                    do {
                        try await statusViewModel.onAmend()
                    } catch {
                        errorString = error.localizedDescription
                    }
                }
            })
    }
}
