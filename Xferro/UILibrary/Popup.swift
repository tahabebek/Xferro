//
//  Popup.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

struct P118_CustomPopup: View {

    @State private var isPresented: Bool = false

    var body: some View {
        ZStack {
            Color.clear
            VStack {
                Spacer()
                Button {
                    isPresented = true
                } label: {
                    Text("Show Popup")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .buttonStyle(PlainButtonStyle())
                Spacer()
                Spacer()
                Spacer()
            }
            .padding()
        }
        .popup(isPresented: $isPresented, style: .blur) {
            Text("Popup")
        }
    }
}

enum PopupStyle {
    case blur
    case dimmed
    case none
}

struct Popup<Message>: ViewModifier where Message: View {

    @Binding var isPresented: Bool
    var size: CGSize = CGSize(width: 200, height: 150)
    let style: PopupStyle
    let message: Message

    func body(content: Content) -> some View {
        content
            .blur(radius: style == .blur ? (isPresented ? 6 : 0) : 0)
            .overlay(
                Rectangle()
                    .fill(Color.black.opacity(style == .dimmed ? (isPresented ? 0.3 : 0) : 0))
            )
            .overlay(popupContent)
            .animation(.easeInOut(duration: 0.26), value: isPresented)
    }

    private var popupContent: some View {
        GeometryReader { proxy in
            ZStack {
                Color.clear
                VStack {
                    self.message
                }
                .frame(width: self.size.width, height: self.size.height)
                .background(Color.blue)
                .cornerRadius(15)
                .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 0)
                .overlay(
                    ZStack {
                        HStack {
                            Spacer()
                            Image(systemName: "xmark")
                                .font(.system(size: 16))
                                .padding(.trailing, 12)
                        }
                        self.topIcon
                    }
                    , alignment: .top)
            }
        }
        .scaleEffect(isPresented ? 1.0 : 0.85)
        .opacity(isPresented ? 1.0 : 0)
        .animation(.easeInOut(duration: 0.26), value: isPresented)
    }

    private var topIcon: some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .overlay(
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 40))
                    .foregroundColor(Color.white)
            )
            .offset(y: -20)
    }
}

struct PopupToggle: ViewModifier {

    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content
            .disabled(isPresented)
            .onTapGesture {
                self.isPresented.toggle()
            }
    }
}

extension View {
    func popup<T>(
        isPresented: Binding<Bool>,
        size: CGSize = CGSize(width: 200, height: 150),
        style: PopupStyle = .blur,
        @ViewBuilder content: () -> T) -> some View where T : View
    {
        let popup = Popup(isPresented: isPresented, size: size, style: style, message: content())
        let popupToggle = PopupToggle(isPresented: isPresented)
        let modifiedContent = self.modifier(popup).modifier(popupToggle)
        return modifiedContent
    }
}

#Preview {
    P118_CustomPopup()
}
