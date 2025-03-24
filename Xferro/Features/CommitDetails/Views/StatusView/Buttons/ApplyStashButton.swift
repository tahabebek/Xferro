//
//  ApplyStashButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/18/25.
//

import SwiftUI

struct ApplyStashButton: View {
    @Binding var selectedStashToApply: SelectableStash?
    @Binding var errorString: String?
    @State var stashOptions: [XFButtonOption<SelectableStash>] = []

    let title: String
    let stashes: [SelectableStash]
    let onApplyStash: (SelectableStash) async throws -> Void

    init(
        selectedStashToApply: Binding<SelectableStash?> = .constant(nil),
        errorString: Binding<String?> = .constant(nil),
        title: String,
        stashes: [SelectableStash],
        onApplyStash: @escaping (SelectableStash) async throws -> Void
    ) {
        self._selectedStashToApply = selectedStashToApply
        self._errorString = errorString
        self.title = title
        self.stashes = stashes
        self.onApplyStash = onApplyStash

        self._stashOptions = State(
            initialValue: stashes.map {
                XFButtonOption(title: $0.stash.message, data: $0)
            })
    }

    var body: some View {
        XFButton<SelectableStash>(
            title: title,
            info: XFButtonInfo(info: InfoTexts.applyStash),
            disabled: stashes.isEmpty,
            options: $stashOptions,
            onTapOption: { option in
                selectedStashToApply = option.data
            },
            onTap: {
                if let selectedStashToApply {
                    Task {
                        do {
                            try await onApplyStash(selectedStashToApply)
                        } catch {
                            errorString = error.localizedDescription
                        }
                    }

                }
            }
        )
        .onChange(of: stashes.count) {
            stashOptions = stashes.map { XFButtonOption(title: $0.stash.message, data: $0) }
        }
    }
}
