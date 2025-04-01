//
//  ApplyStashButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/18/25.
//

import SwiftUI

struct ApplyStashButton: View {
    @Binding var selectedStashToApply: SelectableStash?
    @State var stashOptions: [XFButtonOption<SelectableStash>] = []

    let title: String
    let stashes: [SelectableStash]
    let onApplyStash: (SelectableStash) -> Void

    init(
        selectedStashToApply: Binding<SelectableStash?> = .constant(nil),
        title: String,
        stashes: [SelectableStash],
        onApplyStash: @escaping (SelectableStash) -> Void
    ) {
        self._selectedStashToApply = selectedStashToApply
        self.title = title
        self.stashes = stashes
        self.onApplyStash = onApplyStash

        self._stashOptions = State(
            initialValue: stashes.map {
                XFButtonOption(title: $0.stash.message, data: $0)
            })
    }

    var body: some View {
        XFButton<SelectableStash,Text>(
            title: title,
            info: XFButtonInfo(info: InfoTexts.applyStash),
            disabled: stashes.isEmpty,
            options: $stashOptions,
            onTapOption: { option in
                selectedStashToApply = option.data
            },
            onTap: {
                if let selectedStashToApply {
                    onApplyStash(selectedStashToApply)
                }
            }
        )
        .onChange(of: stashes.count) {
            stashOptions = stashes.map { XFButtonOption(title: $0.stash.message, data: $0) }
        }
    }
}
