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
        git_libgit2_init()
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

        // TODO: create a clone with -depth 1, and only for the current branch, and then create worktrees for the autowips for each commit
        // git clone *REMOTE-URL* --branch *BRANCH-NAME* --single-branch --depth 1 *FOLDER*


        createMenu()
        FirebaseApp.configure()
        FirebaseConfiguration.shared.setLoggerLevel(.min)
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
        git_libgit2_shutdown()
        let app = NSApplication.shared
        app.reply(toApplicationShouldTerminate: true)
    }
}

