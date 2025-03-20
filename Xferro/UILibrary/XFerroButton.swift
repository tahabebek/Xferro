//
//  XFerroButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct XFerroButtonOption<OptionData>: Identifiable {
    var id: String { title }
    var isHovered: Bool = false
    let title: String
    let data: OptionData
}

struct XFerroButtonInfo {
    let title: String?
    let info: String

    init(title: String? = nil, info: String) {
        self.title = title
        self.info = info
    }
}

struct XFerroButton<OptionData>: View {
    @Binding var selectedOptionIndex: Int
    @Binding var options: [XFerroButtonOption<OptionData>]
    @State var showingOptions: Bool = false
    @State var showingInfo: Bool = false
    @State var addMoreIsHovered: Bool = false
    @State private var searchText = ""

    let title: String
    let info: XFerroButtonInfo?
    let disabled: Bool
    let dangerous: Bool
    let isProminent: Bool
    let isSmall: Bool
    let addMoreOptionsText: String?
    let showsSearchOptions: Bool
    let onTapOption: (XFerroButtonOption<OptionData>) -> Void
    let onTapAddMore: () -> Void
    let onTap: () -> Void

    init(
        title: String,
        info: XFerroButtonInfo? = nil,
        disabled: Bool = false,
        dangerous: Bool = false,
        isProminent: Bool = true,
        isSmall: Bool = false,
        options: Binding<[XFerroButtonOption<OptionData>]> = .constant([]),
        selectedOptionIndex: Binding<Int> = .constant(0),
        addMoreOptionsText: String? = nil,
        showsSearchOptions: Bool = false,
        onTapOption: @escaping (XFerroButtonOption<OptionData>) -> Void = { _ in },
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
        self.showsSearchOptions = showsSearchOptions
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
                        infoView()
                    }
                } else {
                    HStack(spacing: 4) {
                        Text(title)
                        optionsView()
                        infoView()
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
                Label(options[selectedOptionIndex].title, systemImage: "arrowtriangle.down.fill")
                    .labelStyle(RightImageLabelStyle())
                    .lineLimit(1)
                    .frame(maxWidth: 72)
                    .fixedSize()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingOptions.toggle()
                    }
                    .popover(isPresented: $showingOptions) {
                        XFerroButtonPopover(
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

    @ViewBuilder func infoView() -> some View {
        if let info {
            Image(systemName: "info.circle")
                .frame(width: 16, height: 16)
                .contentShape(Rectangle())
                .onTapGesture {
                    showingInfo.toggle()
                }
                .popover(isPresented: $showingInfo) {
                    VStack(spacing: 0) {
                        if let title = info.title {
                            Text(title)
                                .font(.title)
                                .padding(.vertical)
                        }
                        ScrollView {
                            Text(info.info)
                                .font(.body)
                                .padding(.vertical)
                        }
                    }
                    .padding()
                    .frame(maxWidth: 400, maxHeight: 600)
                }
        }
    }
}
