//
//  XFerroButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct XFerroButton: View {
    let title: String
    let disabled: Bool
    let dangerous: Bool
    let isProminent: Bool
    let isSmall: Bool
    let onTap: () -> Void

    init(
        title: String,
        disabled: Bool = false,
        dangerous: Bool = false,
        isProminent: Bool = true,
        isSmall: Bool = false,
        onTap: @escaping () -> Void
    ) {
        self.title = title
        self.disabled = disabled
        self.dangerous = dangerous
        self.isProminent = isProminent
        self.isSmall = isSmall
        self.onTap = onTap
    }
    var body: some View {
        buttonWith(
            title: title,
            disabled: disabled,
            dangerous: dangerous,
            isProminent: isProminent,
            isSmall: isSmall,
            action: onTap
        )
    }

    @ViewBuilder func buttonWith(
        title: String,
        disabled: Bool = false,
        dangerous: Bool = false,
        isProminent: Bool = true,
        isSmall: Bool = false,
        action: @escaping () -> Void) -> some View {
            Button {
                action()
            } label: {
                Group {
                    if dangerous {
                        HStack(spacing: 4) {
                            ZStack {
                                Image(systemName: "octagon.fill")
                                    .foregroundStyle(.red)
                                Image(systemName: "exclamationmark")
                                    .resizable(resizingMode: .stretch)
                                    .frame(width: 3, height: 6)
                                    .aspectRatio(contentMode: .fit)
                                    .scaledToFit()
                            }
                            Text(title)
                        }
                    } else {
                        Text(title)
                    }
                }
            }
            .disabled(disabled)
            .style(isDisabled: disabled, isProminent: isProminent, isSmall: isSmall)
        }
}
