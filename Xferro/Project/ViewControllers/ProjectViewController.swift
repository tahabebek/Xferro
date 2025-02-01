//
//  ProjectViewController.swift
//  Xferro
//
//  Created by Taha Bebek on 1/9/25.
//

import AppKit
import SwiftUI

class ProjectViewController: NSViewController {
    enum AutoCommitStrategy {
        case memory
        case disk
    }

    private let user: User
    private var currentProject: Project
    private var autocommitStrategy: AutoCommitStrategy

    init(user: User, autoCommitStrategy: AutoCommitStrategy = .disk) {
        self.user = user
        self.autocommitStrategy = autoCommitStrategy
        guard let project = user.projects.currentProject else {
            fatalError("User's current project is nil")
        }
        self.currentProject = project

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let projectView = ProjectView(projectViewModel: ProjectViewModel(user: user, project: currentProject))
        let hostingController = NSHostingController(rootView: projectView)

        addChild(hostingController)
        view.addSubview(hostingController.view)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func loadView() {
        let selectProjectView = NSView()
        selectProjectView.wantsLayer = true
        view = selectProjectView
    }
}
