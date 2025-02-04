//
//  FlaredRounded.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

struct FlaredRounded<Content>: View where Content: View {
    var backgroundColor: Color = Color(hex: 0x232834).opacity(0.8)
    var intensity: CGFloat = 0.5
    var cornerRadius: CGFloat = 12
    var gradient = Gradient(colors: [
        Color.white,
        Color(hex: 0xA85F89),
        Color(hex: 0xA85F89).opacity(0)
    ])
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(backgroundColor)
                .overlay(
                    GeometryReader { proxy in
                        ZStack(alignment: .topLeading) {
                            LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                                .mask(
                                    RoundedCorners(tl: cornerRadius)
                                )
                                .opacity(0.12)

                            LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                                .mask(
                                    RoundedCorners(tl: cornerRadius)
                                        .strokeBorder(lineWidth: 1)
                                )
                                .opacity(0.6)
                        }
                        .frame(width: getSquareSize(proxy).width, height: getSquareSize(proxy).height)
                        .mask(
                            LinearGradient(gradient: Gradient(colors: [
                                Color.black,
                                Color.black.opacity(0),
                                Color.black.opacity(0)
                            ]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    }
                        .opacity(intensity)
                )
            content()
        }

    }

    private func getSquareSize(_ proxy: GeometryProxy) -> CGSize {
        var size = proxy.size
        var min = min(size.width, size.height) - cornerRadius
        if min < 0 { min = 0 }
        size = CGSize(width: min, height: min)
        return size
    }
}

public struct P3_FlaredRounded: View {

    let spacing: CGFloat = 20

    public init() {}
    public var body: some View {
        HStack(spacing: spacing) {
            VStack(spacing: spacing) {
                getView("1")
                getView("2")
            }
            HStack(spacing: spacing) {
                VStack(spacing: spacing) {
                    getView("3")
                    getView("4")
                }
                getView("5")
            }
        }
        .padding(.vertical, spacing * 3)
        .padding(.horizontal, spacing)
    }

    private func getView(_ text: String) -> some View {
        FlaredRounded {
            Text(text)
                .font(.title2)
                .foregroundColor(Color.fabulaFore1)
        }
    }
}

#Preview {
    P3_FlaredRounded().preferredColorScheme(.dark)
}
