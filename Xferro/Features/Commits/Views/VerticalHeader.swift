//
//  VerticalHeader.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//


import SwiftUI

struct VerticalHeader<Content>: View where Content: View {
    @State var showMenu: Bool = false
    @State var showInfo: Bool = false

    let title: String
    let titleColor: Color
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let info: String?
    let buttonsView: (() -> Content)?

    init(
        title: String,
        titleColor: Color = .white,
        horizontalPadding: CGFloat = 8.0,
        verticalPadding: CGFloat = 0.0,
        info: String? = nil,
        buttonsView: (() -> Content)? = nil
    ) {
        self.title = title
        self.titleColor = titleColor
        self.buttonsView = buttonsView
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.info = info
    }

    var body: some View {
        HStack {
            Text("\(title)")
                .font(.heading2)
                .foregroundColor(titleColor)
            buttons()
            if let info {
                InfoView(showingInfo: $showInfo, info: XFButtonInfo(info: info))
            }
            Spacer()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
    }

    @ViewBuilder func buttons() -> some View {
        if let buttonsView {
            Button {
                showMenu.toggle()
            } label: {
                Images.actionButtonImage
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .xfPopover(isPresented: $showMenu) {
                buttonsView()
            }
        }
    }
}

