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
        Task { @MainActor in
            await createMenu()
        }
        git_libgit2_init()
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
        // TODO: git config --global rerere.enabled true
        // https://git-scm.com/book/en/v2/Git-Tools-Rerere
        // https://git-scm.com/docs/git-config#Documentation/git-config.txt-gcrerereResolved

        // TODO: run git gc after every operation in autowip repo to pack up objects
        // git gc --aggressive
        // https://git-scm.com/book/en/v2/Git-Internals-Packfiles

        // TODO: add git search
        // The git grep command can help you find any string or regular expression in any of the files in your source code, even older versions of your project.
        // https://git-scm.com/book/en/v2/Git-Tools-Searching#_git_grep

        // TODO: use gitleaks to catch leaks
        // https://github.com/gitleaks/gitleaks

        // TODO: let users add their workflow model
        // https://nvie.com/posts/a-successful-git-branching-model/

        FirebaseApp.configure()
        FirebaseConfiguration.shared.setLoggerLevel(.min)
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        saveBeforeQuit()
        return .terminateLater
    }

    @MainActor private func createMenu() async {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let mainMenu = NSMenu()
            NSApp.mainMenu = mainMenu

            // Create the application menu
            let appMenuItem = NSMenuItem()
            mainMenu.addItem(appMenuItem)

            let appMenu = NSMenu()
            appMenuItem.submenu = appMenu

            appMenu.addItem(
                NSMenuItem(
                    title: "Preferences...",
                    action: #selector(showPreferences),
                    keyEquivalent: ","
                )
            )

            appMenu.addItem(
                NSMenuItem(
                    title: "Quit",
                    action: #selector(NSApplication.terminate(_:)),
                    keyEquivalent: "q"
                )
            )

            let editMenu = NSMenu(title: "Edit")
            let editMenuItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
            editMenuItem.submenu = editMenu

            // Add common edit menu items
            editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
            editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
            editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
            editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

            mainMenu.addItem(editMenuItem)
        }
    }

    @MainActor private func saveBeforeQuit() {
        if let users = Self.users {
            DataManager.save(users, filename: DataManager.usersFileName)
        }
        git_libgit2_shutdown()
        let app = NSApplication.shared
        app.reply(toApplicationShouldTerminate: true)
    }

    @MainActor @objc func showPreferences(_ sender: Any?) {
        PrefsWindowController.shared.window?
            .makeKeyAndOrderFront(nil)
    }

    @MainActor static func showErrorMessage(error: RepoError) {
        let alert = NSAlert()
        alert.messageString = error.message
        alert.beginSheetModal(for: Self.firstWindow)
    }

    static var firstWindow: NSWindow {
        NSApplication.shared.windows.first!
    }
}

