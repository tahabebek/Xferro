//
//  WindowDraggingModifier.swift
//  Xferro
//
//  Created by Taha Bebek on 1/13/25.
//

import AppKit
import SwiftUI

//struct MenuView: NSViewRepresentable {
//    @Environment(ProjectViewModel.self) var projectViewModel
//    
//    class DragView: NSView {
//        private var initialLocation: NSPoint?
//        private var project: Project
//
//        let selectProjectButton: NSButton = {
//            let button = NSButton()
//            button.action = #selector(selectProject)
//            button.translatesAutoresizingMaskIntoConstraints = false
//            return button
//        }()
//
//        init(initialLocation: NSPoint? = nil, project: Project) {
//            self.initialLocation = initialLocation
//            self.project = project
//            super.init(frame: .zero)
//            setupUI()
//        }
//
//        required init(coder: NSCoder) {
//            fatalError()
//        }
//
//        private func setupUI() {
//            selectProjectButton.title = project.url.lastPathComponent + " ↓"
//            addSubview(selectProjectButton)
//            selectProjectButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
//            selectProjectButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
//        }
//
//        @objc func selectProject() {
//            
//        }
//
//        override func mouseDown(with event: NSEvent) {
//            initialLocation = event.locationInWindow
//        }
//        override func mouseDragged(with event: NSEvent) {
//            guard let initialLocation = initialLocation,
//                  let window = window else { return }
//
//            let currentLocation = event.locationInWindow
//            let newOriginX = window.frame.origin.x + (currentLocation.x - initialLocation.x)
//            let newOriginY = window.frame.origin.y + (currentLocation.y - initialLocation.y)
//
//            window.setFrameOrigin(NSPoint(x: newOriginX, y: newOriginY))
//        }
//    }
//
//    func makeNSView(context: Context) -> NSView {
//        return DragView(project: projectViewModel.project)
//    }
//
//    func updateNSView(_ nsView: NSView, context: Context) {}
//}
