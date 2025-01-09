//
//  AppDelegate.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    override init() {
        super.init()
        print("app delegate init")
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let contentVC = RepositoryViewController()

        // Create window
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.contentViewController = contentVC
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.isReleasedWhenClosed = false
    }
}

