//
//  ApplyStashButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/18/25.
//

import SwiftUI

struct ApplyStashButton: View {
    @Environment(StatusViewModel.self) var statusViewModel
    let stashes: [SelectableStash]
    @Binding var selectedStashToApply: SelectableStash?
    @Binding var errorString: String?

    let title: String

    var body: some View {
        let stashOptions: [XFerroButtonOption<SelectableStash>] = stashes
            .map { XFerroButtonOption(title: $0.stash.message, data: $0) }
        XFerroButton<SelectableStash>(
            title: title,
            disabled: stashes.isEmpty,
            options: stashOptions,
            showsSearchOptions: true,
            onTapOption: { option in
                selectedStashToApply = option.data
            },
            onTap: {
                if let selectedStashToApply {
                    Task {
                        do {
                            try await statusViewModel.onApplyStash(stash: selectedStashToApply)
                        } catch {
                            errorString = error.localizedDescription
                        }
                    }

                }
            }
        )
    }
}
