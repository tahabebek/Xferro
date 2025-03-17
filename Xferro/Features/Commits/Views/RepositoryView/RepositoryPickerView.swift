//
//  RepositoryPickerView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct RepositoryPickerView: View {
    @Binding var selection: RepositoryView.Section

    var body: some View {
        Picker(selection: $selection) {
            Group {
                Text("Branches")
                    .tag(RepositoryView.Section.commits)
                Text("Tags")
                    .tag(RepositoryView.Section.tags)
                Text("Stashes")
                    .tag(RepositoryView.Section.stashes)
                Text("History")
                    .tag(RepositoryView.Section.history)
            }
            .font(.callout)
        } label: {
            Text("Hidden Label")
        }
        .pickerStyle()
        .animation(.default, value: selection)
    }
}

private struct PickerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .labelsHidden()
            .padding(.trailing, 2)
            .background(Color(hexValue: 0x0B0C10))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .pickerStyle(SegmentedPickerStyle())
    }
}

private extension View {
    func pickerStyle() -> some View {
        modifier(PickerModifier())
    }
}
