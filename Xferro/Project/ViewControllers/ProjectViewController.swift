//
//  ProjectViewController.swift
//  Xferro
//
//  Created by Taha Bebek on 1/9/25.
//

import AppKit

class ProjectViewController: NSViewController {
    private let user: User
    private var currentProject: Project
    private var currentCommit: Commit

    private var commitsViewController: CommitsViewController!
    private var commitDetailViewController: CommitDetailViewController!
    private var fileDetailViewController: FileDetailViewController!

    lazy var topBar: NSToolbar = {
        let toolbar = NSToolbar(identifier: NSToolbar.Identifier("ProjectToolbar"))
        toolbar.delegate = self
        toolbar.displayMode = .default
        return toolbar
    }()

    private lazy var splitView: NSSplitView = {
        splitView = NSSplitView()
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.wantsLayer = true
        splitView.layer?.backgroundColor = NSColor.white.cgColor

        commitsViewController = CommitsViewController(project: currentProject)
        addChild(commitsViewController)

        splitView.addSubview(commitsViewController.view)
        commitsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        commitsViewController.view.widthAnchor.constraint(greaterThanOrEqualToConstant: Dimensions.commitsViewWidth).isActive = true
        commitsViewController.view.heightAnchor.constraint(equalTo: splitView.heightAnchor).isActive = true

        commitDetailViewController = CommitDetailViewController(commit: currentCommit)
        addChild(commitDetailViewController)

        splitView.addSubview(commitDetailViewController.view)
        commitDetailViewController.view.translatesAutoresizingMaskIntoConstraints = false
        commitDetailViewController.view.widthAnchor.constraint(greaterThanOrEqualToConstant: Dimensions.commitDetailsViewWidth).isActive = true
        commitDetailViewController.view.heightAnchor.constraint(equalTo: splitView.heightAnchor).isActive = true

        fileDetailViewController = FileDetailViewController()
        addChild(fileDetailViewController)

        splitView.addSubview(fileDetailViewController.view)
        fileDetailViewController.view.translatesAutoresizingMaskIntoConstraints = false
        fileDetailViewController.view.widthAnchor.constraint(greaterThanOrEqualToConstant: Dimensions.fileDetailsViewWidth).isActive = true
        fileDetailViewController.view.heightAnchor.constraint(equalTo: splitView.heightAnchor).isActive = true

        splitView.setHoldingPriority(NSLayoutConstraint.Priority(253), forSubviewAt: 0)
        splitView.setHoldingPriority(NSLayoutConstraint.Priority(252), forSubviewAt: 1)
        splitView.setHoldingPriority(NSLayoutConstraint.Priority(251), forSubviewAt: 2)
        splitView.setPosition(Dimensions.commitsViewWidth, ofDividerAt: 0)
        splitView.setPosition(Dimensions.commitsViewWidth + Dimensions.commitDetailsViewWidth, ofDividerAt: 1)
        return splitView
    }()

    init(user: User) {
        self.user = user
        guard let project = user.projects.currentProject else {
            fatalError("User's current project is nil")
        }
        self.currentProject = project

        guard let lastCommit = currentProject.commits.last else {
            fatalError("Project's commits are nil")
        }
        self.currentCommit = lastCommit

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.toolbar = topBar
        self.view.window?.toolbarStyle = .automatic
        view.window?.title = currentProject.url.lastPathComponent
        print("project \(currentProject.url), isGit \(currentProject.isGit)")
    }

    override func loadView() {
        view = splitView
    }
}

extension ProjectViewController: NSToolbarDelegate {
    private struct ToolbarItemIdentifier {
        static let add = NSToolbarItem.Identifier("addItem")
        static let settings = NSToolbarItem.Identifier("settingsItem")
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            ToolbarItemIdentifier.add,
            ToolbarItemIdentifier.settings,
            .flexibleSpace
        ]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            ToolbarItemIdentifier.add,
            .flexibleSpace,
            ToolbarItemIdentifier.settings
        ]
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case ToolbarItemIdentifier.add:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Add"
            item.paletteLabel = "Add Item"
            item.image = NSImage(systemSymbolName: "plus", accessibilityDescription: "Add")
            item.target = self
            item.action = #selector(addItemTapped)
            return item

        case ToolbarItemIdentifier.settings:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Settings"
            item.paletteLabel = "Open Settings"
            item.image = NSImage(systemSymbolName: "gear", accessibilityDescription: "Settings")
            item.target = self
            item.action = #selector(settingsTapped)
            return item

        default:
            return nil
        }
    }

    @objc func addItemTapped() {
        print("Add item tapped")
    }

    @objc func settingsTapped() {
        print("Settings tapped")
    }
}
