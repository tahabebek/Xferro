//
//  XFerroButtonStyle.swift
//  Xferro
//
//  Created by Taha Bebek on 2/21/25.
//

import SwiftUI

struct XFerroButtonStyle: ButtonStyle {
    let foregroundColor: Color
    let regularBackgroundColor: Color
    let prominentBackgroundColor: Color
    let pressedOpacity: CGFloat
    let disabledOpacity: CGFloat
    let isDisabled: Bool
    let isProminent: Bool
    let isSmall: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(isSmall ? .caption : .callout)
            .padding(.vertical, isSmall ? 2 : 3)
            .padding(.horizontal, isSmall ? 4 : 6)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isProminent ? prominentBackgroundColor : regularBackgroundColor)
            )
            .foregroundColor(foregroundColor)
            .opacity(configuration.isPressed ? pressedOpacity : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
            .overlay {
                if isDisabled {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(disabledOpacity))

                }
            }
    }
}

extension View {
    func style(
        foregroundColor: Color = .white,
        regularBackgroundColor: Color = .gray.opacity(0.4),
        prominentBackgroundColor: Color = .accentColor.opacity(0.7),
        pressedOpacity: CGFloat = 0.8,
        disabledOpacity: CGFloat = 0.6,
        isDisabled: Bool = false,
        isProminent: Bool = true,
        isSmall: Bool = false
    ) -> some View {
        buttonStyle(XFerroButtonStyle(
            foregroundColor: foregroundColor,
            regularBackgroundColor: regularBackgroundColor,
            prominentBackgroundColor: prominentBackgroundColor,
            pressedOpacity: pressedOpacity,
            disabledOpacity: disabledOpacity,
            isDisabled: isDisabled,
            isProminent: isProminent,
            isSmall: isSmall
        ))
    }
}
