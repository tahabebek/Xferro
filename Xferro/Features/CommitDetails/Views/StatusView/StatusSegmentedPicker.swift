//
//  StatusSegmentedPicker.swift
//  Xferro
//
//  Created by Taha Bebek on 4/2/25.
//

import SwiftUI

struct StatusSegmentedPicker: NSViewRepresentable {
    enum Section: Int {
        case currentChanges = 0
        case history = 1
        case wipHistory = 2
        case tags = 3
        case stashes = 4
    }
    
    @Binding var selection: StatusSegmentedPicker.Section
    
    func makeNSView(context: Context) -> NSSegmentedControl {
        let control = NSSegmentedControl()
        control.segmentCount = 5
        control.setLabel("Current Changes", forSegment: 0)
        control.setLabel("History", forSegment: 1)
        control.setLabel("Wip History", forSegment: 2)
        control.setLabel("Tags", forSegment: 3)
        control.setLabel("Stashes", forSegment: 4)

        control.trackingMode = .selectOne
        control.target = context.coordinator
        control.action = #selector(Coordinator.segmentChanged(_:))
        control.font = .segmentedControl

        updateSelection(control)
        return control
    }
    
    func updateNSView(_ nsView: NSSegmentedControl, context: Context) {
        updateSelection(nsView)
    }
    
    private func updateSelection(_ control: NSSegmentedControl) {
        switch selection {
        case .currentChanges:
            control.selectedSegment = 0
        case .history:
            control.selectedSegment = 1
        case .wipHistory:
            control.selectedSegment = 2
        case .tags:
            control.selectedSegment = 3
        case .stashes:
            control.selectedSegment = 4
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: StatusSegmentedPicker
        
        init(_ parent: StatusSegmentedPicker) {
            self.parent = parent
        }
        
        @objc func segmentChanged(_ sender: NSSegmentedControl) {
            switch sender.selectedSegment {
            case 0:
                parent.selection = .currentChanges
            case 1:
                parent.selection = .history
            case 2:
                parent.selection = .wipHistory
            case 3:
                parent.selection = .tags
            case 4:
                parent.selection = .stashes
            default:
                break
            }
        }
    }
}
