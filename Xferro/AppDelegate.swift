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
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let contentVC = LandingViewController()

        // Create window
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: Dimensions.appWidth, height: Dimensions.appHeight),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.setFrameAutosaveName("Xferro")
        window.titlebarAppearsTransparent = true
        window.contentViewController = contentVC
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.isReleasedWhenClosed = false
    }
}

