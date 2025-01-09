//
//  LandingViewController.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import AppKit

class LandingViewController: NSViewController {
    private var usersLoader = UsersLoader()
    private var userObservation: Any?

    override func viewDidLoad() {
        super.viewDidLoad()
        userObservation = withObservationTracking {
            usersLoader.users
        } onChange: {
            Task { @MainActor [weak self] in
                guard let self else { return }
                handleNewUsers(users: usersLoader.users)
            }
        }

        Task {
            try? await usersLoader.loadUsers()
        }
    }

    private func handleNewUsers(users: Users?) {
        guard let users else {
            showLoginViewController(with: users)
            return
        }

        if let currentUser = users.currentUser {
            showProjectsViewController(with: currentUser)
        } else {
            showLoginViewController(with: users)
        }
    }

    private func showProjectsViewController(with user: User) {
        let projectsViewController = ProjectsViewController(user: user)
        addChild(projectsViewController)
        view.addSubview(projectsViewController.view)

        projectsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        projectsViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        projectsViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        projectsViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        projectsViewController.view.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
    }

    private func showLoginViewController(with users: Users?) {
        let loginViewController = LoginViewController(users: users)
        addChild(loginViewController)
        view.addSubview(loginViewController.view)

        loginViewController.view.translatesAutoresizingMaskIntoConstraints = false
        loginViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        loginViewController.view.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
    }

    override func loadView() {
        let landingView = NSView()
        landingView.wantsLayer = true
        landingView.translatesAutoresizingMaskIntoConstraints = false
        landingView.widthAnchor.constraint(greaterThanOrEqualToConstant: Dimensions.appWidth).isActive = true
        landingView.heightAnchor.constraint(greaterThanOrEqualToConstant: Dimensions.appHeight).isActive = true
//
//        let label = NSTextField(labelWithString: "Landing")
//        label.font = NSFont.systemFont(ofSize: 16)
//        label.textColor = NSColor.white
//
//        label.isEditable = false
//        label.isSelectable = false
//        label.isBordered = false
//        label.drawsBackground = false
//        landingView.addSubview(label)
//
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.centerXAnchor.constraint(equalTo: landingView.centerXAnchor).isActive = true
//        label.centerYAnchor.constraint(equalTo: landingView.centerYAnchor).isActive = true
        view = landingView
    }
}
