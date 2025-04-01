//
//  IdentityView.swift
//  Xferro
//
//  Created by Taha Bebek on 1/16/25.
//

import SwiftUI

struct IdentityView: View {
    @Bindable var viewModel: IdentityViewModel
    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(spacing: 30) {
            Text("Configure Git")
                .font(.heading1)
            Text("This information helps label and track the commits you make. Keep in mind that if you share your commits, everyone can view these details.")
                .font(.paragraph4)
                .foregroundStyle(.secondary)
                .padding(.top, 20)
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Author")
                        .font(.formHeading)
                        .foregroundStyle(.secondary)

                    TextField("", text: $viewModel.name)
                        .textFieldStyle(.plain)
                        .frame(height: 38)
                        .padding(.horizontal, 12)
                        .cornerRadius(6)
                        .font(.formField)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .focused($isNameFocused)
                        .onAppear {
                            isNameFocused = true
                        }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.formField)
                        .foregroundStyle(.secondary)

                    HStack {
                        TextField("", text: $viewModel.email)
                            .font(.formField)
                            .textFieldStyle(.plain)
                    }
                    .frame(height: 38)
                    .padding(.horizontal, 12)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                XFButton<Void,Text>(title: "Finish") {
                    viewModel.finishButtonTapped()
                }
                .frame(width: 300)
            }
            .frame(width: 300)
        }
    }
}
