//
//  PeekView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/21/25.
//

import SwiftUI

struct PeekView: View {
    @Environment(PeekViewModel.self) var peekViewModel
    var body: some View {
        Color.clear.ignoresSafeArea()
            .overlay {
                VStack {
                    Spacer()
                    Text(peekViewModel.peekInfo.title)
                    Spacer()
                }
            }
    }
}
