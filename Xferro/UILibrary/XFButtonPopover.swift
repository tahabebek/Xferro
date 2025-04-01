//
//  XFButtonPopover.swift
//  Xferro
//
//  Created by Taha Bebek on 3/18/25.
//

import Foundation

import SwiftUI

struct XFButtonPopover<T>: View {
    @Binding var showingOptions: Bool
    @Binding var options: [XFButtonOption<T>]
    @State var addMoreIsHovered: Bool = false
    @State var addMoreIsHovered2: Bool = false
    @State var addMoreIsHovered3: Bool = false
    
    @Binding var selectedOptionIndex: Int

    let addMoreOptionsText: String?
    let addMoreOptionsText2: String?
    let addMoreOptionsText3: String?
    let onTapOption: (XFButtonOption<T>) -> Void
    let onTapAddMore: () -> Void
    let onTapAddMore2: () -> Void
    let onTapAddMore3: () -> Void
    
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
            if let addMoreOptionsText2 {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .opacity(addMoreIsHovered2 ? 0.7 : 0)
                    Text(addMoreOptionsText2)
                        .onTapGesture {
                            showingOptions = false
                            onTapAddMore2()
                        }
                        .onHover { flag in
                            addMoreIsHovered2 = flag
                        }
                }
            }
            if let addMoreOptionsText3 {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .opacity(addMoreIsHovered3 ? 0.7 : 0)
                    Text(addMoreOptionsText3)
                        .onTapGesture {
                            showingOptions = false
                            onTapAddMore3()
                        }
                        .onHover { flag in
                            addMoreIsHovered3 = flag
                        }
                }
            }
            Spacer()
        }
    }
}
