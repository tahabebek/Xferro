//
//  Popup.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

enum PopupBackgroundStyle {
    case blur
    case dimmed
    case none
}

struct Popup<Message>: ViewModifier where Message: View {

    @Binding var isPresented: Bool
    let backgroundStyle: PopupBackgroundStyle
    let isDestructive: Bool
    let message: () -> Message
    let onCancel: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .blur(radius: backgroundStyle == .blur ? (isPresented ? 6 : 0) : 0)
            .overlay(
                Rectangle()
                    .fill(Color.black.opacity(backgroundStyle == .dimmed ? (isPresented ? 0.3 : 0) : 0))
            )
            .overlay(popupContent)
            .animation(.easeInOut(duration: 0.26), value: isPresented)
    }

    private var popupContent: some View {
        GeometryReader { proxy in
            ZStack {
                Color.clear
                VStack {
                    self.message()
                }
                .background(
                    Color(hexValue: 0x15151A)
                        .cornerRadius(8)
                )
                .cornerRadius(15)
                .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 0)
                .overlay(
                    ZStack {
                        HStack {
                            Spacer()
                            Image(systemName: "xmark")
                                .frame(width: 16, height: 16)
                                .contentShape(Rectangle())
                                .font(.system(size: 16))
                                .padding(.trailing, 12)
                                .padding(.top, isDestructive ? 0 : 12)
                                .onTapGesture {
                                    onCancel?()
                                    isPresented = false
                                }
                        }
                        if isDestructive {
                            self.stopIcon
                        }
                    }
                    , alignment: .top)
            }
        }
        .scaleEffect(isPresented ? 1.0 : 0.85)
        .opacity(isPresented ? 1.0 : 0)
        .animation(.easeInOut(duration: 0.26), value: isPresented)

    }

    private var stopIcon: some View {
        Octagon()
            .stroke(Color.white, lineWidth: 3)
            .fill(Color.red)
            .frame(width: 40, height: 40)
            .overlay(
                Text("STOP")
                    .font(.caption)
                    .foregroundColor(Color.white)
            )
            .offset(y: -20)
    }
}

extension View {
    func popup<T>(
        isPresented: Binding<Bool>,
        backgroundStyle: PopupBackgroundStyle = .blur,
        isDestructive: Bool = false,
        @ViewBuilder content: @escaping () -> T,
        onCancel: (() -> Void)? = nil) -> some View where T : View
    {
        let popup = Popup(
            isPresented: isPresented,
            backgroundStyle: backgroundStyle,
            isDestructive: isDestructive,
            message: content,
            onCancel: onCancel
        )
        let modifiedContent = self.modifier(popup)
        return modifiedContent
    }
}
