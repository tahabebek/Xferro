//
//  main.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import Cocoa
import SwiftUI
import TipKit

#if TEST
@main
struct SwiftSpaceApp: App {
    var body: some Scene {
        WindowGroup {
            EmptyView()
        }
    }
}
#else

@main
struct SwiftSpaceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var welcomeViewModel = WelcomeViewModel()
    @State private var discardPopup = DiscardPopup()
    @State private var users: Users? = DataManager.load(Users.self, filename: DataManager.usersFileName)
    @State private var projectsViewModel: ProjectsViewModel? = ProjectsViewModel(user: DataManager.load(Users.self, filename: DataManager.usersFileName)?.currentUser)
    private let screenDimensions = NSScreen.main?.visibleFrame.size

    var body: some Scene {
        WindowGroup {
            Group {
                GeometryReader { geometry in
                    Group {
                        if let projectsViewModel {
                            ProjectsView(viewModel: projectsViewModel)
                                .environment(discardPopup)
                        } else {
                            WelcomeView(viewModel: welcomeViewModel)
                                .onChange(of: welcomeViewModel.users) { oldValue, newValue in
                                    AppDelegate.users = newValue
                                    users = newValue
                                }
                        }
                    }
                    .onChange(of: users) { oldValue, newValue in
                        if let users: Users = newValue {
                            if let currentUser: User = users.currentUser {
                                projectsViewModel = ProjectsViewModel(user: currentUser)
                            }
                        }
                    }
                    .environment(\.windowSize, geometry.size)
                }
            }
//            .frame(idealWidth: Dimensions.appWidth, idealHeight: Dimensions.appHeight)
            .task {
                AppDelegate.users = users
                do {
                    try Tips.configure()
                }
                catch {
                    // Handle TipKit errors
                    print("Error initializing TipKit \(error.localizedDescription)")
                }
            }
            .background(Color.fabulaBack2)
            .popup(
                isPresented: $discardPopup.isPresented,
                backgroundStyle: .blur,
                isDestructive: true
            ) {
                VStack {
                    Text(discardPopup.title)
                        .padding()
                    HStack {
                        XFerroButton<Void>(
                            title: "Cancel",
                            onTap: {
                                discardPopup.onCancel?()
                                discardPopup.isPresented = false
                            }
                        )
                        XFerroButton<Void>(
                            title: "Discard",
                            onTap: {
                                discardPopup.onConfirm?()
                                discardPopup.isPresented = false
                            }
                        )
                    }
                    .padding(.top)
                }
                .padding()
            } onCancel: {
                discardPopup.onCancel?()
            }
        }
    }
}

#endif
