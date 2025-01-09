//
//  LoginViewController.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import AppKit

class LoginViewController: NSViewController {
    let users: Users?

    init(users: Users?) {
        self.users = users
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func loadView() {
        let loginView = NSView()
        loginView.wantsLayer = true

        let label = NSTextField(labelWithString: "Login")
        label.font = NSFont.systemFont(ofSize: 16)
        label.textColor = NSColor.white

        label.isEditable = false
        label.isSelectable = false
        label.isBordered = false
        label.drawsBackground = false
        loginView.addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: loginView.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: loginView.centerYAnchor).isActive = true
        view = loginView
    }
}
