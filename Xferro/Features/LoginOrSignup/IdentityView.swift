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
                .font(.title)
            Text("This information helps label and track the commits you make. Keep in mind that if you share your commits, everyone can view these details.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .padding(.top, 20)
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Author")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)

                    TextField("", text: $viewModel.name)
                        .textFieldStyle(.plain)
                        .frame(height: 38)
                        .padding(.horizontal, 12)
                        .cornerRadius(6)
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
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)

                    HStack {
                        TextField("", text: $viewModel.email)
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
                Button {
                    viewModel.finishButtonTapped()
                } label: {
                    Text("Finish")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(width: 300)
            }
            .frame(width: 300)
        }
    }
}
