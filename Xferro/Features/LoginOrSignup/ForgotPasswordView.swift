//
//  ForgotPasswordView.swift
//  Xferro
//
//  Created by Taha Bebek on 1/16/25.
//

import SwiftUI

struct ForgotPasswordView: View {
    @Bindable var viewModel: ForgotPasswordViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 24) {
            Text("Reset Password")
                .font(.heading2)
            Text("Enter your email address and we'll send you instructions to reset your password.")
                .font(.paragraph3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.paragraph3)
                    .foregroundStyle(.secondary)
                TextField("", text: $viewModel.email)
                    .textFieldStyle(.plain)
                    .frame(height: 38)
                    .padding(.horizontal, 12)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .font(.formField)
            }
            .frame(width: 300)

            // Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Button("Send Reset Link") {
                    viewModel.sendButtonTapped()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
            }
            .padding(.top, 8)
        }
        .padding(30)
        .frame(width: 400)
    }
}
