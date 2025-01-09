//
//  FileDetailViewController.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import AppKit

class FileDetailViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func loadView() {
        let fileDetailView = NSView()
        fileDetailView.wantsLayer = true
        fileDetailView.layer?.backgroundColor = NSColor.blue.cgColor
        fileDetailView.translatesAutoresizingMaskIntoConstraints = false
        fileDetailView.widthAnchor.constraint(greaterThanOrEqualToConstant: 700).isActive = true
        view = fileDetailView
    }
}
