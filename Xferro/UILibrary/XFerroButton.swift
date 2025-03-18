//
//  XFerroButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct XFerroButtonOption: Identifiable {
    var id: String { title }
    var isHovered: Bool = false
    let title: String
}

struct XFerroButton: View {
    @State var filteredOptions: [XFerroButtonOption] = []
    @State var showingOptions: Bool = false
    @State var addMoreIsHovered: Bool = false
    @State var selectedOptionIndex: Int = 0
    @State private var searchText = ""

    let title: String
    let disabled: Bool
    let dangerous: Bool
    let isProminent: Bool
    let isSmall: Bool
    let options: [XFerroButtonOption]
    let addMoreOptionsText: String?
    let showsSearchOptions: Bool
    let onTapOption: (XFerroButtonOption) -> Void
    let onTapAddMore: () -> Void
    let onTap: () -> Void

    init(
        title: String,
        disabled: Bool = false,
        dangerous: Bool = false,
        isProminent: Bool = true,
        isSmall: Bool = false,
        options: [XFerroButtonOption] = [],
        addMoreOptionsText: String? = nil,
        showsSearchOptions: Bool = false,
        onTapOption: @escaping (XFerroButtonOption) -> Void = { _ in },
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
            VStack(alignment: .leading, spacing: 8) {
                Section {
                    ForEach(filteredOptions.indices, id:\.self) { index in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.accentColor)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .opacity(filteredOptions[index].isHovered ? 0.7 : 0)
                            Text(filteredOptions[index].title)
                                .onTapGesture {
                                    showingOptions = false
                                    onTapOption(filteredOptions[index])
                                }
                                .onHover { flag in
                                    filteredOptions[index].isHovered = flag
                                }
                        }
                    }
                } header: {
                    if showsSearchOptions {
                        TextField("Search", text: $searchText)
                            .cornerRadius(8)
                            .frame(maxWidth: .infinity)
                    }
                }
                if let addMoreOptionsText {
                    Divider()
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .opacity(addMoreIsHovered ? 0.7 : 0)
                        Text(addMoreOptionsText)
                            .onTapGesture {
                                showingOptions = false
                                onTapAddMore()
                            }
                            .onHover { flag in
                                addMoreIsHovered = flag
                            }
                    }
                }
                Spacer()
            }
            .padding()
            .onChange(of: searchText) { oldValue, newValue in
                if newValue.isEmpty {
                    filteredOptions = options
                } else {
                    filteredOptions = options.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
                }

            }
        }
    }

    @ViewBuilder func buttonWith(
        title: String,
        disabled: Bool = false,
        dangerous: Bool = false,
        isProminent: Bool = true,
        isSmall: Bool = false,
        options: [XFerroButtonOption] = [],
        addMoreOptionsText: String? = nil,
        showsSearchOptions: Bool = false,
        onTapOption: @escaping (XFerroButtonOption) -> Void = { _ in },
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
                Label(filteredOptions[selectedOptionIndex].title, systemImage: "arrowtriangle.down.fill")
                    .labelStyle(RightImageLabelStyle())
                    .fixedSize()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingOptions.toggle()
                    }
            }
        }
    }
}
