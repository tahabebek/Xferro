//
//  XFerroButtonPopover.swift
//  Xferro
//
//  Created by Taha Bebek on 3/18/25.
//

import Foundation

import SwiftUI

struct XFerroButtonPopover<T>: View {
    @Binding var showingOptions: Bool
    @Binding var options: [XFerroButtonOption<T>]
    @Binding var addMoreIsHovered: Bool
    @Binding var selectedOptionIndex: Int

    let addMoreOptionsText: String?
    let onTapOption: (XFerroButtonOption<T>) -> Void
    let onTapAddMore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Section {
                ForEach(options.indices, id:\.self) { index in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .opacity(options[index].isHovered ? 0.7 : 0)
                        Text(options[index].title)
                            .onTapGesture {
                                showingOptions = false
                                selectedOptionIndex = index
                                onTapOption(options[index])
                            }
                            .onHover { flag in
                                options[index].isHovered = flag
                            }
                    }
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
    }
}
