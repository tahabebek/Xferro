//
//  NSAlert++.swift
//  Xferro
//
//  Created by Taha Bebek on 3/15/25.
//

import Foundation

extension NSAlert {
    static func confirm(
        message: UIString,
        infoString: UIString? = nil,
        actionName: UIString,
        isDestructive: Bool = false,
        parentWindow: NSWindow,
        action: @escaping () -> Void
    ) {
        let alert = NSAlert()
        alert.messageString = message
        if let infoString {
            alert.informativeString = infoString
        }
        alert.addButton(withString: actionName)
        alert.addButton(withString: .cancel)
        alert.buttons[0].hasDestructiveAction = isDestructive
        alert.beginSheetModal(for: parentWindow) { response in
            if response == .alertFirstButtonReturn {
                action()
            }
        }
    }

    static func showMessage(
        window: NSWindow? = nil,
        message: UIString,
        infoString: UIString? = nil
    ) {
        let alert = NSAlert()

        alert.messageString = message
        if let infoString {
            alert.informativeString = infoString
        }
        if let window {
            alert.alertStyle = .critical // appear over existing sheet
            alert.beginSheetModal(for: window)
        }
        else {
            alert.runModal()
        }
    }
}
