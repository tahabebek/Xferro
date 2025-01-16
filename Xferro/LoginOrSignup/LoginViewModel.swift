//
//  LoginViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 1/16/25.
//

import FirebaseAuth
import Observation

@Observable class LoginViewModel {
    var email = ""
    var password = ""
    var showError = false
    var showCheckYourEmailMessage = false
    var errorMessage: String?
    var forgotPasswordViewModel: ForgotPasswordViewModel?

    private var validateEmailLive = false
    private var validatePasswordLive = false
    private var emailObserver: Any?
    private var passwordObserver: Any?
    private let validator = PasswordValidator()
    @ObservationIgnored var onLoginSuccess: ((FirebaseAuth.User?) -> Void)?
    @ObservationIgnored var onSignupTapped: (() -> Void)?
    @ObservationIgnored var shouldShowProgress: ((Bool) -> Void)?

    func loginButtonTapped() {
        shouldShowProgress?(true)
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self else { return }
            shouldShowProgress?(false)
            if let error {
                showError(error)
                return
            }
            guard let user = authResult?.user else {
                showUnkownError()
                return
            }
            onLoginSuccess?(user)
        }
    }

    private func showError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }

    private func showUnkownError() {
        errorMessage = "An unknown error occurred."
        showError = true
    }

    func forgotPasswordButtonTapped() {
        let newForgotPasswordViewModel = ForgotPasswordViewModel { [weak self] enteredText in
            guard let self else { return }
            shouldShowProgress?(true)
            Auth.auth().sendPasswordReset(withEmail: enteredText) { [weak self] error in
                guard let self else { return }
                shouldShowProgress?(false)
                if let error {
                    showError(error)
                    return
                }
                showCheckYourEmailMessage = true
            }
        }
        self.forgotPasswordViewModel = newForgotPasswordViewModel
    }

    func signupButtonTapped() {
        onSignupTapped?()
    }
}
