//
//  AppDelegate.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import Cocoa
import FirebaseCore
import Mixpanel
import Sentry

class AppDelegate: NSObject, NSApplicationDelegate {
    static var users: Users?
    var window: NSWindow!

    override init() {
        super.init()
        SentrySDK.start { options in
            options.dsn = "https://06fd8ebf14ce84b23c1252a0b78d790b@o4508498687033344.ingest.us.sentry.io/4508498688409600"
            options.tracesSampleRate = 1.0
            options.enableTimeToFullDisplayTracing = true
#if DEBUG
            options.environment = "development"
#else
            options.environment = "production"
#endif
        }
        let mixpanel = Mixpanel.initialize(token: "92209304ee0ef56b6014dd75dd87ac5a")
        mixpanel.track(event: "App launched")
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
        FirebaseConfiguration.shared.setLoggerLevel(.min)

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

