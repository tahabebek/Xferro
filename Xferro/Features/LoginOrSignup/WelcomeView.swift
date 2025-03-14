//
//  WelcomeView.swift
//  Xferro
//
//  Created by Taha Bebek on 1/16/25.
//

import SwiftUI

struct WelcomeView: View {
    let viewModel: WelcomeViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Group {
            VStack(spacing: 0) {
                Spacer()
                HStack(spacing: 0) {
                    Spacer()
                    if viewModel.showProgress {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Group {
                            switch viewModel.currentStep {
                            case .login:
                                LoginView(viewModel: viewModel.loginViewModel)
                                    .padding()
                            case .signup:
                                SignupView(viewModel: viewModel.signupViewModel)
                                    .padding()
                            case .identity:
                                IdentityView(viewModel: viewModel.identityViewModel)
                                    .frame(maxHeight: 500)
                                    .padding()
                            }
                        }
                    }
                    Spacer()
                }
                Spacer()
            }
        }
        .animation(.default, value: viewModel.currentStep)
        .background(colorScheme == .dark ? Color(NSColor.windowBackgroundColor) : Color(NSColor.controlBackgroundColor))
        .overlay(alignment: .topTrailing) {
            if !viewModel.showProgress {
                Button("Skip") {
                    viewModel.skipButtonTapped()
                }
                .font(.system(size: 13))
                .buttonStyle(.plain)
                .padding()
            }
        }
        .overlay(alignment: .topLeading) {
            if case .signup = viewModel.currentStep, !viewModel.showProgress {
                Button("Back") {
                    viewModel.backButtonTapped()
                }
                .font(.system(size: 13))
                .buttonStyle(.plain)
                .padding()
            }
        }
    }
}
