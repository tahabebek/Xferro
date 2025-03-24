//
//  SearchablePicker.swift
//  Xferro
//
//  Created by Taha Bebek on 3/24/25.
//

import SwiftUI

import SwiftUI

struct SearchablePickerView: View {
    let items: [String]
    @Binding var selectedItem: String
    let title: String

    @State private var searchText = ""

    var filteredItems: [String] {
        if searchText.isEmpty {
            return items
        } else {
            return items.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                TextField("Filter", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 100)
                Picker("", selection: $selectedItem) {
                    ForEach(filteredItems, id: \.self) { item in
                        Text(item).tag(item)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .font(.formField)
        .onChange(of: filteredItems) {
            if !filteredItems.contains(selectedItem) {
                selectedItem = filteredItems.first ?? ""
            }
        }
    }
}
