//
//  SignupViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 1/16/25.
//

import FirebaseAuth
import Observation

@Observable class SignupViewModel {
    var fullName = ""
    var email = ""
    var password = ""
    var confirmPassword = ""
    var validationErrors: [String] = []
    var showError = false
    var errorString: String?

    @ObservationIgnored var onSignupSuccess: ((FirebaseAuth.User?) -> Void)?
    @ObservationIgnored var shouldShowProgress: ((Bool) -> Void)?

    private let emailValidator = EmailValidator()
    private let passwordValidator = PasswordValidator()

    var isValidForm: Bool {
        validateForm()
        return validationErrors.isEmpty
    }

    private func validateForm() {
        var errors: [String] = []

        if fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Full name is required")
        }

        if !emailValidator.isValidEmail(email) {
            errors.append("Please enter a valid email address")
        }

        let passwordErrors = passwordValidator.validate(password)
        errors.append(contentsOf: passwordErrors)

        if password != confirmPassword {
            errors.append("Passwords do not match")
        }

        DispatchQueue.main.async {
            self.validationErrors = errors
        }
    }

    func signupButtonTapped() {
        shouldShowProgress?(true)
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self else { return }
            shouldShowProgress?(false)
            if let error {
                errorString = error.localizedDescription
                showError = true
                return
            }
            guard let user = authResult?.user else {
                errorString = "Failed to create user."
                showError = true
                return
            }
            onSignupSuccess?(user)
        }
    }
}
