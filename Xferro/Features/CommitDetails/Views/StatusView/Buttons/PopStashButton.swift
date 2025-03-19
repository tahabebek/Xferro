//
//  PopStashButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/18/25.
//

import SwiftUI

struct PopStashButton: View {
    @Environment(StatusViewModel.self) var statusViewModel
    let stashes: [SelectableStash]
    @Binding var errorString: String?
    
    let title: String

    var body: some View {
        XFerroButton<Void>(
            title: title,
            disabled: stashes.isEmpty,
            onTap: {
                Task {
                    do {
                        try await statusViewModel.onPopStash()
                    } catch {
                        errorString = error.localizedDescription
                    }
                }
            }
        )
    }
}
