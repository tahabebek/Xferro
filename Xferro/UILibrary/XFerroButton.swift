//
//  XFerroButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct XFerroButtonOption<T>: Identifiable {
    var id: String { title }
    var isHovered: Bool = false
    let title: String
    let data: T
}

struct XFerroButton<T>: View {
    @Binding var selectedOptionIndex: Int
    @Binding var options: [XFerroButtonOption<T>]
    @State var showingOptions: Bool = false
    @State var addMoreIsHovered: Bool = false
    @State private var searchText = ""

    let title: String
    let disabled: Bool
    let dangerous: Bool
    let isProminent: Bool
    let isSmall: Bool
    let addMoreOptionsText: String?
    let showsSearchOptions: Bool
    let onTapOption: (XFerroButtonOption<T>) -> Void
    let onTapAddMore: () -> Void
    let onTap: () -> Void

    init(
        title: String,
        disabled: Bool = false,
        dangerous: Bool = false,
        isProminent: Bool = true,
        isSmall: Bool = false,
        options: Binding<[XFerroButtonOption<T>]> = .constant([]),
        selectedOptionIndex: Binding<Int> = .constant(0),
        addMoreOptionsText: String? = nil,
        showsSearchOptions: Bool = false,
        onTapOption: @escaping (XFerroButtonOption<T>) -> Void = { _ in },
        onTapAddMore: @escaping () -> Void = {},
        onTap: @escaping () -> Void
    ) {
        self.title = title
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
        buttonWith(
            title: title,
            disabled: disabled,
            dangerous: dangerous,
            isProminent: isProminent,
            isSmall: isSmall,
            options: options,
            addMoreOptionsText: addMoreOptionsText,
            showsSearchOptions: showsSearchOptions,
            onTapOption: onTapOption,
            onTapAddMore: onTapAddMore,
            action: onTap
        )
    }

    @ViewBuilder func buttonWith(
        title: String,
        disabled: Bool = false,
        dangerous: Bool = false,
        isProminent: Bool = true,
        isSmall: Bool = false,
        options: [XFerroButtonOption<T>] = [],
        addMoreOptionsText: String? = nil,
        showsSearchOptions: Bool = false,
        onTapOption: @escaping (XFerroButtonOption<T>) -> Void = { _ in },
        onTapAddMore: @escaping () -> Void = {},
        action: @escaping () -> Void) -> some View {
            Button {
                action()
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
                        }
                    } else {
                        HStack(spacing: 4) {
                            Text(title)
                            optionsView()
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
}
