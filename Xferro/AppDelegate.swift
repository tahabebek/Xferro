//
//  AppDelegate.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import Cocoa
import FirebaseCore

class AppDelegate: NSObject, NSApplicationDelegate {
    static var users: Users?
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
        window.titlebarAppearsTransparent = true
        window.contentViewController = contentVC
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.isReleasedWhenClosed = false

        FirebaseApp.configure()
        createMenu()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        saveBeforeQuit()
        return .terminateLater
    }

    private func createMenu() {
        let mainMenu = NSMenu()
        NSApp.mainMenu = mainMenu

        // Create the application menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu

        // Add the Quit item
        appMenu.addItem(NSMenuItem(title: "Quit",
                                   action: #selector(NSApplication.terminate(_:)),
                                   keyEquivalent: "q"))
    }

    private func saveBeforeQuit() {
        if let users = Self.users {
            DataManager.save(users, filename: Constants.usersFileName)
        }
        let app = NSApplication.shared
        app.reply(toApplicationShouldTerminate: true)
    }
}

