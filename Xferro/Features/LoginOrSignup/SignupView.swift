//
//  SignupView.swift
//  Xferro
//
//  Created by Taha Bebek on 1/16/25.
//

import SwiftUI

struct SignupView: View {
    @State var viewModel: SignupViewModel
    @State private var isSecured = true
    @State private var triedSignup = false
    @FocusState private var isNameFocused: Bool

    var body: some View {
        Group {
            content
                .alert(Text("Error"), isPresented: $viewModel.showError) {
                    Button {
                        viewModel.showError = false
                        viewModel.errorString = nil
                    } label: { Text("OK") }
                } message: {
                    Text(viewModel.errorString ?? "Failed to sign up. Please try again later.")
                }
        }
    }

    @ViewBuilder var content: some View {
        VStack(spacing: 30) {
            Text("Sign up to Xferro")
                .font(.title)
            HStack(alignment: .top) {
                Spacer()
                VStack {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)

                            TextField("", text: $viewModel.fullName)
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

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)

                            HStack {
                                if isSecured {
                                    SecureField("", text: $viewModel.password)
                                        .textFieldStyle(.plain)
                                } else {
                                    TextField("", text: $viewModel.password)
                                        .textFieldStyle(.plain)
                                }

                                Button(action: { isSecured.toggle() }) {
                                    Image(systemName: isSecured ? "eye.slash" : "eye")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .frame(height: 38)
                            .padding(.horizontal, 12)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }


                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)

                            HStack {
                                if isSecured {
                                    SecureField("", text: $viewModel.confirmPassword)
                                        .textFieldStyle(.plain)
                                } else {
                                    TextField("", text: $viewModel.confirmPassword)
                                        .textFieldStyle(.plain)
                                }

                                Button(action: { isSecured.toggle() }) {
                                    Image(systemName: isSecured ? "eye.slash" : "eye")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .frame(height: 38)
                            .padding(.horizontal, 12)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    .frame(width: 300)
                    Button {
                        triedSignup = true
                        if viewModel.isValidForm {
                            viewModel.signupButtonTapped()
                        }
                    } label: {
                        Text("Sign Up")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(width: 300)
                }

                if !viewModel.validationErrors.isEmpty, triedSignup {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.validationErrors, id: \.self) { error in
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.title3)
                        }
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .animation(.default, value: triedSignup)
    }
}
