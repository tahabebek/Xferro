//
//  CommitDetailViewController.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import AppKit

class CommitDetailViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func loadView() {
        let commitDetailView = NSView()
        commitDetailView.wantsLayer = true
        commitDetailView.layer?.backgroundColor = NSColor.red.cgColor
        commitDetailView.translatesAutoresizingMaskIntoConstraints = false
        commitDetailView.widthAnchor.constraint(greaterThanOrEqualToConstant: 300).isActive = true
        view = commitDetailView
    }
}
