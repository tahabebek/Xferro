//
//  ProjectsViewController.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import Cocoa

class ProjectsViewController: NSViewController {
    let user: User

    init(user: User) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let currentProject = user.projects.currentProject {
            showProjectView(project: currentProject)
        }
    }

    override func loadView() {
        let projectsView = NSView()
        projectsView.wantsLayer = true
        view = projectsView
    }

    private func showProjectView(project: Project) {
        let projectViewController = ProjectViewController(user: user)
        addChild(projectViewController)
        view.addSubview(projectViewController.view)

        projectViewController.view.translatesAutoresizingMaskIntoConstraints = false
        projectViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        projectViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        projectViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        projectViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }
}
