//
//  SelectProjectViewController.swift
//  Xferro
//
//  Created by Taha Bebek on 1/9/25.
//

import AppKit

class SelectProjectViewController: NSViewController {
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
    }

    override func loadView() {
        let selectProjectView = NSView()
        selectProjectView.wantsLayer = true

        let label = NSTextField(labelWithString: "Select Project")
        label.font = NSFont.systemFont(ofSize: 16)
        label.textColor = NSColor.white

        label.isEditable = false
        label.isSelectable = false
        label.isBordered = false
        label.drawsBackground = false
        selectProjectView.addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: selectProjectView.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: selectProjectView.centerYAnchor).isActive = true
        view = selectProjectView
    }
}
