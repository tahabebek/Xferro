//
//  TriStateCheckbox.swift
//  Xferro
//
//  Created by Taha Bebek on 3/8/25.
//

import SwiftUI

enum CheckboxState {
    case checked
    case unchecked
    case partiallyChecked
}

struct TriStateCheckbox: View {
    @Binding var state: CheckboxState
    var onTap: () -> Void

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(Color.gray, lineWidth: 1)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white)
            )
            .overlay {
                switch state {
                case .checked:
                    Image(systemName: "checkmark")
                        .font(.small).bold()
                        .foregroundColor(.accentColor)
                case .unchecked:
                    Color.clear
                case .partiallyChecked:
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: 10, height: 2)
                }
            }
            .onTapGesture {
                onTap()
            }
    }
}
