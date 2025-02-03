//
//  WelcomeViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 1/16/25.
//

import FirebaseAuth
import Observation

@Observable class WelcomeViewModel {
    enum Step {
        case login
        case signup
        case identity
    }

    var currentStep: Step = .login
    var showProgress = false
    var users: Users?

    @ObservationIgnored let loginViewModel: LoginViewModel
    @ObservationIgnored let signupViewModel: SignupViewModel
    @ObservationIgnored let identityViewModel: IdentityViewModel
    private var fireBaseUser: FirebaseAuth.User?
    private var identity: CommitIdentity?

    init() {
        self.loginViewModel = LoginViewModel()
        self.signupViewModel = SignupViewModel()
        self.identityViewModel = IdentityViewModel()

        self.loginViewModel.onLoginSuccess = { [weak self] fireBaseUser in
            guard let self else { return }
            self.fireBaseUser = fireBaseUser
            currentStep = .identity
        }

        self.loginViewModel.shouldShowProgress = { [weak self] flag in
            guard let self else { return }
            self.showProgress = flag
        }

        self.loginViewModel.onSignupTapped = { [weak self] in
            guard let self else { return }
            currentStep = .signup
        }

        self.signupViewModel.onSignupSuccess = { [weak self] fireBaseUser in
            guard let self else { return }
            self.fireBaseUser = fireBaseUser
            currentStep = .identity
        }

        self.signupViewModel.shouldShowProgress = { [weak self] flag in
            guard let self else { return }
            self.showProgress = flag
        }

        self.identityViewModel.onIdentityEntered = { [weak self] identity in
            guard let self else { return }
            self.identity = identity
            handleFinish()
        }
    }

    func skipButtonTapped() {
        showProgress = true
        switch currentStep {
        case .login, .signup:
            Auth.auth().signInAnonymously { [weak self] result, error in
                guard let self else { return }
                showProgress = false
                fireBaseUser = result?.user
                self.currentStep = .identity
            }
        case .identity:
            handleFinish()
        }
    }

    func backButtonTapped() {
        switch currentStep {
        case .identity, .login:
            fatalError()
        case .signup:
            currentStep = .login
        }
    }

    private func handleFinish() {
        let identity = self.identity ?? CommitIdentity(name: "Author", email: "author@example.com")

        let login: Login = if let fireBaseUser {
            if fireBaseUser.email == identity.email {
                .email
            } else if fireBaseUser.isAnonymous {
                .anonymous
            } else {
                fatalError()
            }
        } else {
            .failedToAuthGuest
        }

        let user = User(
            userID: fireBaseUser?.uid ?? UUID().uuidString,
            login: login,
            commitIdentity: identity
        )
        users = Users(currentUser: user, recentUsers: [])
    }
}
