//
//  XFButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct XFButtonOption<OptionData>: Identifiable {
    var id: String { title }
    var isHovered: Bool = false
    let title: String
    let data: OptionData
}

struct XFButtonInfo {
    let info: String
}

struct XFButton<OptionData, Content>: View where Content : View {
    @Binding var selectedOptionIndex: Int
    @Binding var options: [XFButtonOption<OptionData>]
    @State var showingOptions: Bool = false
    @State var showingInfo: Bool = false
    @State private var searchText = ""

    let content: () -> Content
    let info: XFButtonInfo?
    let optionWidth: CGFloat
    let disabled: Bool
    let dangerous: Bool
    let isProminent: Bool
    let isSmall: Bool
    let addMoreOptionsText: String?
    let addMoreOptionsText2: String?
    let addMoreOptionsText3: String?
    let onTapOption: (XFButtonOption<OptionData>) -> Void
    let onTapAddMore: () -> Void
    let onTapAddMore2: () -> Void
    let onTapAddMore3: () -> Void
    let onTap: () -> Void
    let otherActionsTapped: (() -> Void)?

    init(
        @ViewBuilder content: @escaping () -> Content,
        info: XFButtonInfo? = nil,
        optionWidth: CGFloat = 72.0,
        disabled: Bool = false,
        dangerous: Bool = false,
        isProminent: Bool = true,
        isSmall: Bool = false,
        options: Binding<[XFButtonOption<OptionData>]> = .constant([]),
        selectedOptionIndex: Binding<Int> = .constant(0),
        addMoreOptionsText: String? = nil,
        addMoreOptionsText2: String? = nil,
        addMoreOptionsText3: String? = nil,
        onTapOption: @escaping (XFButtonOption<OptionData>) -> Void = { _ in },
        onTapAddMore: @escaping () -> Void = {},
        onTapAddMore2: @escaping () -> Void = {},
        onTapAddMore3: @escaping () -> Void = {},
        onTap: @escaping () -> Void,
        otherActionsTapped: (() -> Void)? = nil
    ) {
        self.content = content
        self.info = info
        self.optionWidth = optionWidth
        self.disabled = disabled
        self.dangerous = dangerous
        self.isProminent = isProminent
        self.isSmall = isSmall
        self._options = options
        self._selectedOptionIndex = selectedOptionIndex
        self.addMoreOptionsText = addMoreOptionsText
        self.addMoreOptionsText2 = addMoreOptionsText2
        self.addMoreOptionsText3 = addMoreOptionsText3
        self.onTapOption = onTapOption
        self.onTapAddMore = onTapAddMore
        self.onTapAddMore2 = onTapAddMore2
        self.onTapAddMore3 = onTapAddMore3
        self.onTap = onTap
        self.otherActionsTapped = otherActionsTapped
    }
    
    var body: some View {
        Button {
            onTap()
        } label: {
            Group {
                if dangerous {
                    HStack(spacing:4) {
                        ZStack {
                            Image(systemName: "octagon.fill")
                                .foregroundStyle(.red)
                            Image(systemName: "exclamationmark")
                                .resizable(resizingMode: .stretch)
                                .frame(width: 3, height: 6)
                                .aspectRatio(contentMode: .fit)
                                .scaledToFit()
                        }
                        content()
                            .fixedSize()
                        optionsView
                        if otherActionsTapped != nil {
                            otherActionsView
                        }
                        if let info {
                            InfoView(showingInfo: $showingInfo, info: info)
                        }
                    }
                } else {
                    HStack(spacing: 4) {
                        content()
                            .fixedSize()
                        optionsView
                        if otherActionsTapped != nil {
                            otherActionsView
                        }
                        if let info {
                            InfoView(showingInfo: $showingInfo, info: info)
                        }
                    }
                }
            }
        }
        .disabled(disabled)
        .style(isDisabled: disabled, isProminent: isProminent, isSmall: isSmall)
    }
    
    @ViewBuilder var otherActionsView: some View {
        Images.actionButtonImage
            .frame(width: 16, height: 16)
            .contentShape(Rectangle())
            .onTapGesture {
                otherActionsTapped?()
            }
    }

    @ViewBuilder var optionsView: some View {
        if options.count > selectedOptionIndex {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.fabulaBack2.opacity(0.7))
                    .frame(width: optionWidth + 8)
                Label(
                    options[selectedOptionIndex].title,
                    systemImage: Images.actionButtonSystemImageName
                )
                .font(.paragraph5)
                .labelStyle(
                    RightImageLabelStyle()
                )
                .lineLimit(1)
                .frame(width: optionWidth)
                .fixedSize()
                .contentShape(Rectangle())
                .onTapGesture {
                    showingOptions.toggle()
                }
                .popover(isPresented: $showingOptions) {
                    XFButtonPopover(
                        showingOptions: $showingOptions,
                        options: $options,
                        selectedOptionIndex: $selectedOptionIndex,
                        addMoreOptionsText: addMoreOptionsText,
                        addMoreOptionsText2: addMoreOptionsText2,
                        addMoreOptionsText3: addMoreOptionsText3,
                        onTapOption: onTapOption,
                        onTapAddMore: onTapAddMore,
                        onTapAddMore2: onTapAddMore2,
                        onTapAddMore3: onTapAddMore3
                    )
                    .padding()
                }
            }
        }
    }
}

extension XFButton where Content == Text {
    init(
        title: String,
        info: XFButtonInfo? = nil,
        optionWidth: CGFloat = 72,
        disabled: Bool = false,
        dangerous: Bool = false,
        isProminent: Bool = true,
        isSmall: Bool = false,
        options: Binding<[XFButtonOption<OptionData>]> = .constant([]),
        selectedOptionIndex: Binding<Int> = .constant(0),
        addMoreOptionsText: String? = nil,
        addMoreOptionsText2: String? = nil,
        addMoreOptionsText3: String? = nil,
        onTapOption: @escaping (XFButtonOption<OptionData>) -> Void = { _ in },
        onTapAddMore: @escaping () -> Void = {},
        onTapAddMore2: @escaping () -> Void = {},
        onTapAddMore3: @escaping () -> Void = {},
        onTap: @escaping () -> Void,
        otherActionsTapped: (() -> Void)? = nil
    ) {
        self.content = {
            Text(title)
        }
        self.info = info
        self.optionWidth = optionWidth
        self.disabled = disabled
        self.dangerous = dangerous
        self.isProminent = isProminent
        self.isSmall = isSmall
        self._options = options
        self._selectedOptionIndex = selectedOptionIndex
        self.addMoreOptionsText = addMoreOptionsText
        self.addMoreOptionsText2 = addMoreOptionsText2
        self.addMoreOptionsText3 = addMoreOptionsText3
        self.onTapOption = onTapOption
        self.onTapAddMore = onTapAddMore
        self.onTapAddMore2 = onTapAddMore2
        self.onTapAddMore3 = onTapAddMore3
        self.onTap = onTap
        self.otherActionsTapped = otherActionsTapped
    }
}
