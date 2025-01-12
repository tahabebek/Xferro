//
//  SelectProjectViewController.swift
//  Xferro
//
//  Created by Taha Bebek on 1/9/25.
//

import AppKit
import SwiftUI

class SelectProjectViewController: NSViewController {
    let user: User
    let onURLSelected: (URL) -> Void

    init(user: User, onURLSelected: @escaping (URL) -> Void) {
        self.user = user
        self.onURLSelected = onURLSelected
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let folderPickerView = FolderPickerView() { [weak self] url in
            guard let self else { return }
            onURLSelected(url)
        }

        let hostingController = NSHostingController(rootView: folderPickerView)

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
