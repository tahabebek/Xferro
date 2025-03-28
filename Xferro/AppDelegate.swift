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
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    static var users: Users?
    static var settingsViewController: NSHostingController<SettingsView>?
    static var cloneRepositoryViewController: NSHostingController<AnyView>?
    
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
                action: #selector(showSettings),
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

        let repositoriesMenu = NSMenu(title: "File")
        let repositoriesMenuItem = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        repositoriesMenuItem.submenu = repositoriesMenu

        repositoriesMenu.addItem(withTitle: "New Repository", action: #selector(newRepository), keyEquivalent: "x")
        repositoriesMenu.addItem(withTitle: "Add Local Repository", action: #selector(addLocalRepository), keyEquivalent: "o")
        repositoriesMenu.addItem(withTitle: "Clone Repository", action: #selector(cloneRepository), keyEquivalent: "O")
        mainMenu.addItem(repositoriesMenuItem)

        let editMenu = NSMenu(title: "Edit")
        let editMenuItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        editMenuItem.submenu = editMenu

        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        mainMenu.addItem(editMenuItem)

        let viewMenu = NSMenu(title: "View")
        let viewMenuItem = NSMenuItem(title: "View", action: nil, keyEquivalent: "")
        viewMenuItem.submenu = viewMenu

        // Add items to the View menu
        let toggleSidebarItem = NSMenuItem(title: "Toggle Sidebar", action: #selector(toggleSidebar(_:)), keyEquivalent: "s")
        toggleSidebarItem.keyEquivalentModifierMask = [.command, .control]
        viewMenu.addItem(toggleSidebarItem)

        viewMenu.addItem(NSMenuItem.separator())

        // Add standard View menu items
        viewMenu.addItem(withTitle: "Enter Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")

        // Add Window menu
        let windowMenu = NSMenu(title: "Window")
        let windowMenuItem = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
        windowMenuItem.submenu = windowMenu

        // Add items to the Window menu
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.zoom(_:)), keyEquivalent: "")
        windowMenu.addItem(NSMenuItem.separator())
        windowMenu.addItem(withTitle: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")

        // Add Help menu
        let helpMenu = NSMenu(title: "Help")
        let helpMenuItem = NSMenuItem(title: "Help", action: nil, keyEquivalent: "")
        helpMenuItem.submenu = helpMenu

        helpMenu.addItem(withTitle: "Xferro Help", action: #selector(showHelp(_:)), keyEquivalent: "?")

        mainMenu.addItem(viewMenuItem)
        mainMenu.addItem(windowMenuItem)
        mainMenu.addItem(helpMenuItem)
    }

    @objc private func newRepository(_ sender: Any?) {
    }
    
    static func newRepository() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select A Folder to Initialize as a Git Repository"
        openPanel.prompt = "New Repository"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        openPanel.canCreateDirectories = true
        
        openPanel.begin { result in
            guard result == .OK, let selectedURL = openPanel.url else { return }
            usedDidSelectFolder(selectedURL)
            
            NotificationCenter.default.post(
                name: .newRepositoryAdded,
                object: nil,
                userInfo: [.repositoryURL: selectedURL]
            )
        }
    }

    @objc private func addLocalRepository(_ sender: Any?) {
        Self.addLocalRepository()
    }
    
    static func addLocalRepository() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Local Git Repository"
        openPanel.message = "Choose a folder containing a Git repository"
        openPanel.prompt = "Add Repository"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = false
        openPanel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        
        openPanel.begin { result in
            guard result == .OK, let selectedURL = openPanel.url else { return }
            usedDidSelectFolder(selectedURL)
            
            Task {
                let result = Repository.isValid(url: selectedURL)
                switch result {
                case .success(let isValid):
                    if isValid {
                        NotificationCenter.default.post(
                            name: .localRepositoryAdded,
                            object: nil,
                            userInfo: [.repositoryURL: selectedURL]
                        )
                    } else {
                        await showErrorAlert(message: "The selected directory is not a valid Git repository.")
                    }
                case .failure(let error):
                    await showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func cloneRepository(_ sender: Any?) {
        Task { @MainActor in
            Self.showCloneRepositoryView()
        }
    }
    
    private static func usedDidSelectFolder(_ folder: URL) {
        let gotAccess = folder.startAccessingSecurityScopedResource()
        if !gotAccess { return }
        do {
            let bookmarkData = try folder.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            UserDefaults.standard.set(bookmarkData, forKey: folder.path)
        } catch {
            fatalError("Failed to create bookmark: \(error)")
        }

        folder.stopAccessingSecurityScopedResource()
    }

    @objc func toggleSidebar(_ sender: NSMenuItem) {
    }

    @objc func showHelp(_ sender: NSMenuItem) {
        NSWorkspace.shared.open(URL(string: "https://xferro.ai/contact")!)
    }

    @MainActor private func saveBeforeQuit() {
        if let users = Self.users {
            DataManager.save(users, filename: DataManager.usersFileName)
        }
        git_libgit2_shutdown()
        let app = NSApplication.shared
        app.reply(toApplicationShouldTerminate: true)
    }

    @MainActor @objc func showSettings(_ sender: Any?) {
        Self.showSettings()
    }

    @MainActor static func showSettings() {
        let contentView = SettingsView(
            defaults: UserDefaults.standard,
            config: GitConfig.default!
        ) {
            dismissSettings()
        }
        settingsViewController = NSHostingController(rootView: contentView)
        Self.firstWindow.contentViewController?.presentAsSheet(settingsViewController!)
    }
    
    @MainActor static func showCloneRepositoryView() {
        let cloneView = CloneRepositoryView {
            dismissCloneView()
        } onClone: { destinationPath, sourcePath, isRemote in
            dismissCloneView()
            print("Clone repository to \(destinationPath) from \(sourcePath), isREMOTE: \(isRemote)")
            if isRemote {
                
            } else {
                
            }
        }
        .frame(width: 600, height: 300)

        cloneRepositoryViewController = NSHostingController(
            rootView: AnyView(cloneView)
        )
        Self.firstWindow.contentViewController?.presentAsSheet(cloneRepositoryViewController!)
    }

    @MainActor static func dismissSettings() {
        if let controller = settingsViewController,
           let presentingViewController = controller.presentingViewController {
            presentingViewController.dismiss(controller)
        }
    }

    @MainActor static func dismissCloneView() {
        if let controller = cloneRepositoryViewController,
           let presentingViewController = controller.presentingViewController {
            presentingViewController.dismiss(controller)
        }
    }
    
    @MainActor static func showErrorMessage(error: RepoError) {
        let alert = NSAlert()
        if error.localizedDescription.lines.count < 4 {
            alert.messageText = error.localizedDescription
            alert.informativeText = ""
            alert.alertStyle = .informational
        } else {
            alert.messageText = "Something went wrong"
            alert.informativeText = ""
            alert.alertStyle = .informational

            // Create a scroll view with text view inside
            let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 450, height: 300))
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalScroller = false
            scrollView.autohidesScrollers = true
            scrollView.borderType = .noBorder

            let contentView = NSTextView(frame: scrollView.bounds)
            contentView.isEditable = false
            contentView.isSelectable = true
            contentView.string = error.message.rawValue
            contentView.textContainer?.widthTracksTextView = true
            contentView.textContainer?.containerSize = NSSize(width: scrollView.bounds.width, height: CGFloat.greatestFiniteMagnitude)
            contentView.isVerticallyResizable = true
            contentView.autoresizingMask = [.width]

            scrollView.documentView = contentView

            alert.accessoryView = scrollView
        }

        // Add default button
        alert.addButton(withTitle: "Dismiss")
        alert.beginSheetModal(for: Self.firstWindow)
    }
    
    @MainActor private static func showErrorAlert(message: String, informativeText: String? = nil) {
        let alert = NSAlert()
        alert.messageText = message
        if let informativeText {
            alert.informativeText = informativeText
        }
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    static var firstWindow: NSWindow {
        NSApplication.shared.windows.first!
    }
}

