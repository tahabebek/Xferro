//
//  RepositoryPickerView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI
import AppKit

struct RepositoryPickerView: View {
    @Binding var selection: RepositoryView.Section

    var body: some View {
        CustomSegmentedPicker(selection: $selection)
            .padding(.trailing, 2)
            .background(Color(hexValue: 0x0B0C10))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .animation(.default, value: selection)
    }
}

struct CustomSegmentedPicker: NSViewRepresentable {
    @Binding var selection: RepositoryView.Section
    
    func makeNSView(context: Context) -> NSSegmentedControl {
        let control = NSSegmentedControl()
        control.segmentCount = 4
        control.setLabel("Branches", forSegment: 0)
        control.setLabel("Tags", forSegment: 1)
        control.setLabel("Stashes", forSegment: 2)
        control.setLabel("History", forSegment: 3)
        
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
        case .commits:
            control.selectedSegment = 0
        case .tags:
            control.selectedSegment = 1
        case .stashes:
            control.selectedSegment = 2
        case .history:
            control.selectedSegment = 3
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: CustomSegmentedPicker
        
        init(_ parent: CustomSegmentedPicker) {
            self.parent = parent
        }
        
        @objc func segmentChanged(_ sender: NSSegmentedControl) {
            switch sender.selectedSegment {
            case 0:
                parent.selection = .commits
            case 1:
                parent.selection = .tags
            case 2:
                parent.selection = .stashes
            case 3:
                parent.selection = .history
            default:
                break
            }
        }
    }
}
