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
    @State var filteredOptions: [XFerroButtonOption<T>] = []
    @State var showingOptions: Bool = false
    @State var addMoreIsHovered: Bool = false
    @State var selectedOptionIndex: Int = 0
    @State private var searchText = ""

    let title: String
    let disabled: Bool
    let dangerous: Bool
    let isProminent: Bool
    let isSmall: Bool
    let options: [XFerroButtonOption<T>]
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
        options: [XFerroButtonOption<T>] = [],
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
        self.options = options
        self.filteredOptions = options
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
        .popover(isPresented: $showingOptions) {
            XFerroButtonPopover(
                searchText: $searchText,
                showingOptions: $showingOptions,
                filteredOptions: $filteredOptions,
                addMoreIsHovered: $addMoreIsHovered,
                options: options,
                showsSearchOptions: showsSearchOptions,
                addMoreOptionsText: addMoreOptionsText,
                onTapOption: onTapOption,
                onTapAddMore: onTapAddMore
            )
            .padding()

        }
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
        if options.isNotEmpty {
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.fabulaBack2.opacity(0.7))
                    .frame(maxWidth: 70)
                Label(filteredOptions[selectedOptionIndex].title, systemImage: "arrowtriangle.down.fill")
                    .labelStyle(RightImageLabelStyle())
                    .lineLimit(1)
                    .frame(maxWidth: 60)
                    .fixedSize()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingOptions.toggle()
                    }
            }
        }
    }
}
