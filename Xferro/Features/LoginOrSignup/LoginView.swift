//
//  LoginView.swift
//  Xferro
//
//  Created by Taha Bebek on 1/16/25.
//

import SwiftUI

import SwiftUI

struct LoginView: View {
    @Bindable var viewModel: LoginViewModel
    @State private var isSecured = true

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                contents
                    .sheet(item: $viewModel.forgotPasswordViewModel) { viewModel in
                        ForgotPasswordView(viewModel: viewModel)
                    }
                    .alert(Text("Error"), isPresented: $viewModel.showError) {
                        Button {
                            viewModel.showError = false
                            viewModel.errorMessage = nil
                        } label: { Text("OK") }
                    } message: {
                        Text(viewModel.errorMessage ?? "Something went wrong.")
                    }

                Spacer()
            }
            Spacer()
        }
    }

    @ViewBuilder var contents: some View {
        VStack(spacing: 30) {
            Text("Welcome to Xferro")
            Text("A superior git client.")
            VStack(spacing: 15) {
                Image(systemName: "lock.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                    .foregroundStyle(.blue)
                Text("Sign in to your account")
                    .foregroundStyle(.secondary)
                if viewModel.showCheckYourEmailMessage {
                    Text("Check your email for a verification link.")
                        .foregroundStyle(.purple)
                }
            }
            .padding(.top, 20)

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
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

                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
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
            }
            .frame(width: 300)

            VStack(spacing: 16) {
                Button {
                    viewModel.loginButtonTapped()
                } label: {
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Forgot Password?") {
                    viewModel.forgotPasswordButtonTapped()
                }
                .buttonStyle(.plain)
            }
            .frame(width: 300)

            HStack(spacing: 4) {
                Text("Don't have an account?")
                    .foregroundStyle(.secondary)

                Button("Sign Up") {
                    viewModel.signupButtonTapped()
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
        }
        .frame(width: 400, height: 500)
    }
}
