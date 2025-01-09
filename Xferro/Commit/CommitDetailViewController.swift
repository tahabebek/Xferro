//
//  CommitDetailViewController.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import AppKit

class CommitDetailViewController: NSViewController {
    private let commit: Commit

    init(commit: Commit) {
        self.commit = commit
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func loadView() {
        let commitDetailView = NSView()
        commitDetailView.wantsLayer = true
        commitDetailView.layer?.backgroundColor = NSColor.red.withAlphaComponent(0.1).cgColor

        let label = NSTextField(labelWithString: "Commit Detail")
        label.font = NSFont.systemFont(ofSize: 16)
        label.textColor = NSColor.black

        label.isEditable = false
        label.isSelectable = false
        label.isBordered = false
        label.drawsBackground = false
        commitDetailView.addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: commitDetailView.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: commitDetailView.centerYAnchor).isActive = true

        view = commitDetailView
    }
}
