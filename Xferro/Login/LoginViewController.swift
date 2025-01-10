//
//  LoginViewController.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import AppKit
import FirebaseAuth

class LoginViewController: NSViewController {
    let users: Users?
    var authObserver: NSObjectProtocol
    @IBOutlet weak var welcomeTitle: NSTextField!
    @IBOutlet weak var welcomeSubtitle: NSTextField!
    @IBOutlet weak var loginWithGoggleButton: NSView!
    @IBOutlet weak var loginWithGoogleTitle: NSTextField!
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
    @IBOutlet weak var divider3View: NSView!
    @IBOutlet weak var divider4View: NSView!
    @IBOutlet weak var horizontalDividerTitle: NSTextField!
    @IBOutlet weak var verticalDividerTitle: NSTextField!

    private lazy var dividers: [NSView] = [divider1View, divider2View, divider3View, divider4View]
    private lazy var textFields: [NSTextField] = [loginEmailTextField, loginPasswordTextField, signupEmailTextField, signupPasswordTextField]
    private lazy var passwordTextFields: [NSTextField] = [loginPasswordTextField, signupPasswordTextField]

    private lazy var dividerTitles: [NSTextField] = [horizontalDividerTitle, verticalDividerTitle]

    private lazy var titles: [NSTextField] = [loginWithEmailTitle, loginWithGoogleTitle, signupWithEmailTitle, forgotPasswordTitle, skipTitle]

    init(users: Users?) {
        self.users = users
        authObserver = Auth.auth().addStateDidChangeListener { auth, user in
            print("auth state changed, user \(user?.email ?? "none")")
        }
        super.init(nibName: "LoginViewController", bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
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
            passwordField.placeholderAttributedString = NSAttributedString(
                string: "password",
                attributes: [.foregroundColor: currentTheme.secondaryText]
            )
        }

        loginButton.layer?.backgroundColor = currentTheme.accent.cgColor
        signupButton.layer?.backgroundColor = currentTheme.accent.cgColor
        loginWithGoggleButton.layer?.backgroundColor = currentTheme.accent.cgColor

        for title in titles {
            title.textColor = currentTheme.textAndIcon
        }
    }

    deinit {
        Auth.auth().removeStateDidChangeListener(authObserver)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
