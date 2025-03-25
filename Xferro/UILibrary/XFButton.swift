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

struct XFButton<OptionData>: View {
    @Binding var selectedOptionIndex: Int
    @Binding var options: [XFButtonOption<OptionData>]
    @State var showingOptions: Bool = false
    @State var showingInfo: Bool = false
    @State var addMoreIsHovered: Bool = false
    @State private var searchText = ""

    let title: String
    let info: XFButtonInfo?
    let disabled: Bool
    let dangerous: Bool
    let isProminent: Bool
    let isSmall: Bool
    let addMoreOptionsText: String?
    let onTapOption: (XFButtonOption<OptionData>) -> Void
    let onTapAddMore: () -> Void
    let onTap: () -> Void

    init(
        title: String,
        info: XFButtonInfo? = nil,
        disabled: Bool = false,
        dangerous: Bool = false,
        isProminent: Bool = true,
        isSmall: Bool = false,
        options: Binding<[XFButtonOption<OptionData>]> = .constant([]),
        selectedOptionIndex: Binding<Int> = .constant(0),
        addMoreOptionsText: String? = nil,
        onTapOption: @escaping (XFButtonOption<OptionData>) -> Void = { _ in },
        onTapAddMore: @escaping () -> Void = {},
        onTap: @escaping () -> Void
    ) {
        self.title = title
        self.info = info
        self.disabled = disabled
        self.dangerous = dangerous
        self.isProminent = isProminent
        self.isSmall = isSmall
        self._options = options
        self._selectedOptionIndex = selectedOptionIndex
        self.addMoreOptionsText = addMoreOptionsText
        self.onTapOption = onTapOption
        self.onTapAddMore = onTapAddMore
        self.onTap = onTap
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
                        Text(title)
                        optionsView()
                        if let info {
                            InfoView(showingInfo: $showingInfo, info: info)
                        }
                    }
                } else {
                    HStack(spacing: 4) {
                        Text(title)
                        optionsView()
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

    @ViewBuilder func optionsView() -> some View {
        if options.count > selectedOptionIndex {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.fabulaBack2.opacity(0.7))
                    .frame(maxWidth: 80)
                Label(
                    options[selectedOptionIndex].title,
                    systemImage: Images.actionButtonSystemImageName
                )
                .font(.paragraph5)
                .labelStyle(
                    RightImageLabelStyle()
                )
                .lineLimit(1)
                .frame(maxWidth: 72)
                .fixedSize()
                .contentShape(Rectangle())
                .onTapGesture {
                    showingOptions.toggle()
                }
                .popover(isPresented: $showingOptions) {
                    XFButtonPopover(
                        showingOptions: $showingOptions,
                        options: $options,
                        addMoreIsHovered: $addMoreIsHovered,
                        selectedOptionIndex: $selectedOptionIndex,
                        addMoreOptionsText: addMoreOptionsText,
                        onTapOption: onTapOption,
                        onTapAddMore: onTapAddMore
                    )
                    .padding()
                }
            }
        }
    }
}
