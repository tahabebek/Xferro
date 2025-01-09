//
//  FilesViewController.swift
//  Xferro
//
//  Created by Taha Bebek on 1/9/25.
//

import AppKit

class FilesViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func loadView() {
        let filesView = NSView()
        filesView.wantsLayer = true
        filesView.layer?.backgroundColor = NSColor.red.cgColor

        let label = NSTextField(labelWithString: "Files")
        label.font = NSFont.systemFont(ofSize: 16)
        label.textColor = NSColor.white

        label.isEditable = false
        label.isSelectable = false
        label.isBordered = false
        label.drawsBackground = false
        filesView.addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: filesView.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: filesView.centerYAnchor).isActive = true

        view = filesView
    }
}
