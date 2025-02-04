//
//  AddRepositoryButton.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

struct AddRepositoryButton: View {
    @State var viewModel: CommitsViewModel
    var body: some View {
        HStack {
            Spacer()
            Button {
                viewModel.addRepositoryButtonTapped()
            } label: {
                Text("Add repository")
            }
            .buttonStyle(.bordered)
            .padding()
            Spacer()
        }
    }
}
