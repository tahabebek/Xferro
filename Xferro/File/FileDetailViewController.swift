//
//  FileDetailViewController.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import AppKit

class FileDetailViewController: NSViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func loadView() {
        let fileDetailView = NSView()
        fileDetailView.wantsLayer = true
        fileDetailView.layer?.backgroundColor = NSColor.blue.withAlphaComponent(0.1).cgColor


        let label = NSTextField(labelWithString: "File Detail")
        label.font = NSFont.systemFont(ofSize: 16)
        label.textColor = NSColor.black

        label.isEditable = false
        label.isSelectable = false
        label.isBordered = false
        label.drawsBackground = false
        fileDetailView.addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: fileDetailView.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: fileDetailView.centerYAnchor).isActive = true

        view = fileDetailView
    }
}
