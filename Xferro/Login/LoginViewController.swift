//
//  LoginViewController.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import AppKit
import FirebaseAuth

class LoginViewController: NSViewController, NSTextFieldDelegate {
    private let users: Users?
    @IBOutlet weak var welcomeTitle: NSTextField!
    @IBOutlet weak var welcomeSubtitle: NSTextField!
    @IBOutlet weak var loginEmailTextField: NSTextField!
    @IBOutlet weak var loginPasswordTextField: NSTextField!
    @IBOutlet weak var signupEmailTextField: NSTextField!
    @IBOutlet weak var signupPasswordTextField: NSTextField!

    @IBOutlet weak var forgotPasswordButton: NSView!
    @IBOutlet weak var forgotPasswordTitle: NSTextField!
    @IBOutlet weak var loginButton: NSView!
    @IBOutlet weak var loginWithEmailTitle: NSTextField!
    @IBOutlet weak var signupButton: NSView!
    @IBOutlet weak var signupWithEmailTitle: NSTextField!
    @IBOutlet weak var skipButton: NSView!
    @IBOutlet weak var skipTitle: NSTextField!

    @IBOutlet weak var divider1View: NSView!
    @IBOutlet weak var divider2View: NSView!
    @IBOutlet weak var verticalDividerTitle: NSTextField!

    @IBOutlet weak var invalidEmailLabel: NSTextField!
    @IBOutlet weak var invalidPasswordLabel: NSTextField!

    @IBOutlet weak var loginView: NSView!
    @IBOutlet weak var signupView: NSView!
    @IBOutlet weak var progressView: NSProgressIndicator!
    @IBOutlet weak var checkYourEmailLabel: NSTextField!

    @IBOutlet weak var identityView: NSView!
    @IBOutlet weak var identityFinishTitle: NSTextField!
    @IBOutlet weak var identityFinishButton: NSView!
    @IBOutlet weak var identityNameTextField: NSTextField!
    @IBOutlet weak var identityEmailTextField: NSTextField!

    private var firebaseUserBeforeIdentityCreation: FirebaseAuth.User?

    private lazy var dividers: [NSView] = [divider1View, divider2View]
    private lazy var textFields: [NSTextField] = [
        loginEmailTextField,
        loginPasswordTextField,
        signupEmailTextField,
        signupPasswordTextField,
        identityNameTextField,
        identityEmailTextField
    ]
    private lazy var passwordTextFields: [NSTextField] = [loginPasswordTextField, signupPasswordTextField]

    private lazy var titles: [NSTextField] = [
        loginWithEmailTitle,
        signupWithEmailTitle,
        forgotPasswordTitle,
        skipTitle,
        identityFinishTitle
    ]
    private var validateEmailLive = false
    private var validatePasswordLive = false
    private let onSuccess: (Users) -> Void

    init(users: Users?, onSuccess: @escaping (Users) -> Void) {
        // Note: we don't support recent users yet, so just showing the login screen without them.
        self.users = users
        self.onSuccess = onSuccess
        super.init(nibName: "LoginViewController", bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUIApearance()
        setupGestureRecognizers()
        setupDelegates()
    }

    private func setupDelegates() {
        loginEmailTextField.delegate = self
        loginPasswordTextField.delegate = self
        signupEmailTextField.delegate = self
        signupPasswordTextField.delegate = self
    }

    private func setupUIApearance() {
        for divider in dividers {
            divider.layer?.backgroundColor = currentTheme.divider.cgColor
        }
        view.layer?.backgroundColor = currentTheme.darkPrimary.cgColor
        welcomeTitle.textColor = currentTheme.textAndIcon
        welcomeSubtitle.textColor = currentTheme.lightPrimary

        for textField in textFields {
            textField.layer?.backgroundColor = currentTheme.lightPrimary.withAlphaComponent(0.1).cgColor
            textField.textColor = currentTheme.textAndIcon
        }

        for passwordField in passwordTextFields {
            passwordField.layer?.backgroundColor = currentTheme.lightPrimary.withAlphaComponent(0.1).cgColor
        }

        loginButton.layer?.backgroundColor = currentTheme.accent.cgColor
        signupButton.layer?.backgroundColor = currentTheme.accent.cgColor
        identityFinishButton.layer?.backgroundColor = currentTheme.accent.cgColor

        for title in titles {
            title.textColor = currentTheme.textAndIcon
        }

        welcomeTitle.font = .systemFont(ofSize: 48, weight: .light)
        welcomeTitle.textColor = currentTheme.textAndIcon


        loginEmailTextField.nextKeyView = loginPasswordTextField
        loginPasswordTextField.nextKeyView = loginEmailTextField
        signupEmailTextField.nextKeyView = signupPasswordTextField
        signupPasswordTextField.nextKeyView = signupEmailTextField
        identityNameTextField.nextKeyView = identityEmailTextField
        identityEmailTextField.nextKeyView = identityNameTextField
    }

    private func setupGestureRecognizers() {
        let loginTap = NSClickGestureRecognizer(target: self, action: #selector(loginButtonTapped(_:)))
        loginTap.numberOfClicksRequired = 1
        loginButton.addGestureRecognizer(loginTap)
        let signupTap = NSClickGestureRecognizer(target: self, action: #selector(signupButtonTapped(_:)))
        signupTap.numberOfClicksRequired = 1
        signupButton.addGestureRecognizer(signupTap)
        let forgotTap = NSClickGestureRecognizer(target: self, action: #selector(forgotPasswordButtonTapped(_:)))
        forgotTap.numberOfClicksRequired = 1
        forgotPasswordButton.addGestureRecognizer(forgotTap)
        let skipTap = NSClickGestureRecognizer(target: self, action: #selector(skipButtonTapped(_:)))
        skipTap.numberOfClicksRequired = 1
        skipButton.addGestureRecognizer(skipTap)
        let finishTap = NSClickGestureRecognizer(target: self, action: #selector(finishButtonTapped(_:)))
        finishTap.numberOfClicksRequired = 1
        identityFinishButton.addGestureRecognizer(finishTap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func loginButtonTapped(_ gesture: NSClickGestureRecognizer) {
        showProgress(true)
        Auth.auth().signIn(withEmail: loginEmailTextField.stringValue, password: loginPasswordTextField.stringValue) { [weak self] authResult, error in
            guard let self else { return }
            showProgress(false)
            if let error {
                showError(error)
                return
            }
            guard let user = authResult?.user else {
                showUnkownError()
                return
            }
            handleLogin(with: user)
        }
    }

    @objc func signupButtonTapped(_ gesture: NSClickGestureRecognizer) {
        var hasError: Bool = false
        let email = signupEmailTextField.stringValue
        let password = signupPasswordTextField.stringValue
        if !Validator.isValidEmail(email) {
            hasError = true
            invalidEmailLabel.isHidden = false
            validateEmailLive = true
        }

        if !Validator.isValidPassword(password) {
            hasError = true
            invalidPasswordLabel.isHidden = false
            validatePasswordLive = true
        }
        if !hasError {
            showProgress(true)
            Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
                guard let self else { return }
                showProgress(false)
                if let error {
                    showError(error)
                    return
                }
                guard let user = authResult?.user else {
                    showUnkownError()
                    return
                }
                handleLogin(with: user)
            }
        }
    }

    private func showProgress(_ flag: Bool) {
        loginView.isHidden = flag
        signupView.isHidden = flag
        verticalDividerTitle.isHidden = flag
        for divider in dividers {
            divider.isHidden = flag
        }
        progressView.isHidden = !flag
        if flag {
            progressView.startAnimation(nil)
        }
    }

    private func showError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showUnkownError() {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = "An unknown error occurred."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc func forgotPasswordButtonTapped(_ gesture: NSClickGestureRecognizer) {
        let alert = NSAlert()
        alert.messageText = "Enter the email associated with your account and we will send you a link to reset your password."
        alert.informativeText = "Email address:"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Send instructions")
        alert.addButton(withTitle: "Cancel")

        // Create the text field
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.placeholderString = ""
        alert.accessoryView = textField

        if let window = NSApplication.shared.mainWindow {
            alert.beginSheetModal(for: window) { [weak self] response in
                guard let self else { return }
                if response == .alertFirstButtonReturn {
                    let enteredText = textField.stringValue
                    showProgress(true)
                    Auth.auth().sendPasswordReset(withEmail: enteredText) { [weak self] error in
                        guard let self else { return }
                        showProgress(false)
                        if let error {
                            showError(error)
                            return
                        }
                        checkYourEmailLabel.isHidden = false
                    }
                }
            }
        }
    }

    @objc func skipButtonTapped(_ gesture: NSClickGestureRecognizer) {
        showProgress(true)
        Auth.auth().signInAnonymously { [weak self] result, error in
            guard let self else { return }
            showProgress(false)
            let user = result?.user
            handleLogin(with: user)
        }
    }

    @objc func finishButtonTapped(_ gesture: NSClickGestureRecognizer) {
        let name = if identityNameTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            "Author"
        } else {
            identityNameTextField.stringValue
        }
        let email = if identityEmailTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            "author@example.com"
        } else {
            identityEmailTextField.stringValue
        }

        let login: Login = if let firebaseUserBeforeIdentityCreation {
            if firebaseUserBeforeIdentityCreation.email == email {
                .email
            } else if firebaseUserBeforeIdentityCreation.isAnonymous {
                .anonymous
            } else {
                fatalError()
            }
        } else {
            .failedToAuthGuest
        }

        let user = User(
            userID: firebaseUserBeforeIdentityCreation?.uid ?? UUID().uuidString,
            login: login,
            commitIdentity: .init(name: name, email: email),
            projects: Projects(currentProject: nil, projects: [])
        )
        let newUsers = Users(currentUser: user, recentUsers: [])
        AppDelegate.users = newUsers
        onSuccess(newUsers)
    }
    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }

        switch textField {
        case signupEmailTextField:
            if validateEmailLive {
                if Validator.isValidEmail(textField.stringValue) {
                    invalidEmailLabel.isHidden = true
                } else {
                    invalidEmailLabel.isHidden = false
                }
            }
        case signupPasswordTextField:
            if validatePasswordLive {
                if Validator.isValidPassword(textField.stringValue) {
                    invalidPasswordLabel.isHidden = true
                } else {
                    invalidPasswordLabel.isHidden = false
                }
            }
        case loginEmailTextField, loginPasswordTextField:
            break
        default:
            break
        }
    }

    private func handleLogin(with user: FirebaseAuth.User?) {
        firebaseUserBeforeIdentityCreation = user
        welcomeTitle.stringValue = "Configure Git"
        welcomeSubtitle.stringValue = "This information helps label and track the commits you make. Keep in mind that if you share your commits, everyone can view these details."
        loginView.isHidden = true
        signupView.isHidden = true
        verticalDividerTitle.isHidden = true
        for divider in dividers {
            divider.isHidden = true
        }
        progressView.isHidden = true
        skipButton.isHidden = true
        identityView.isHidden = false
    }
}
