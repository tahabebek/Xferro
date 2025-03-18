//
//  XFerroButtonPopover.swift
//  Xferro
//
//  Created by Taha Bebek on 3/18/25.
//

import Foundation

import SwiftUI

struct XFerroButtonPopover<T>: View {
    @Binding var searchText: String
    @Binding var showingOptions: Bool
    @Binding var filteredOptions: [XFerroButtonOption<T>]
    @Binding var addMoreIsHovered: Bool

    let options: [XFerroButtonOption<T>]
    let showsSearchOptions: Bool
    let addMoreOptionsText: String?
    let onTapOption: (XFerroButtonOption<T>) -> Void
    let onTapAddMore: () -> Void

    var body: some View {
//        ScrollView {
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
            .onChange(of: searchText) { oldValue, newValue in
                if newValue.isEmpty {
                    filteredOptions = options
                } else {
                    filteredOptions = options.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
                }

            }
//        }
    }
}
