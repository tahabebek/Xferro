//
//  ApplyStashButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/18/25.
//

import SwiftUI

struct ApplyStashButton: View {
    @Environment(StatusViewModel.self) var statusViewModel
    @Binding var selectedStashToApply: SelectableStash?
    @Binding var errorString: String?

    let title: String
    let stashes: [SelectableStash]
    @State var stashOptions: [XFerroButtonOption<SelectableStash>] = []

    init(
        selectedStashToApply: Binding<SelectableStash?> = .constant(nil),
        errorString: Binding<String?> = .constant(nil),
        title: String,
        stashes: [SelectableStash]
    ) {
        self._selectedStashToApply = selectedStashToApply
        self._errorString = errorString
        self.title = title
        self.stashes = stashes

        self._stashOptions = State(
            initialValue: stashes.map {
                XFerroButtonOption(title: $0.stash.message, data: $0)
            })
    }

    var body: some View {
        XFerroButton<SelectableStash>(
            title: title,
            disabled: stashes.isEmpty,
            options: $stashOptions,
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
        .onChange(of: stashes.count) {
            stashOptions = stashes.map { XFerroButtonOption(title: $0.stash.message, data: $0) }
        }
    }
}
