//
//  InfoView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/24/25.
//

import SwiftUI

struct InfoView: View {
    @Binding var showingInfo: Bool
    let info: XFButtonInfo
    
    var body: some View {
        Images.infoButtonImage
            .frame(width: 16, height: 16)
            .contentShape(Rectangle())
            .onTapGesture {
                showingInfo.toggle()
            }
            .xfPopover(isPresented: $showingInfo) {
                VStack(spacing: 0) {
                    ScrollView {
                        Text(info.info)
                            .font(.paragraph3)
                            .padding(.vertical)
                    }
                }
                .padding()
                .frame(maxWidth: 600, maxHeight: 800)
            }
    }
}
