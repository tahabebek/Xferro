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
    @State var users: Users? = DataManager.load(Users.self, filename: DataManager.usersFileName)
    private let screenDimensions = NSScreen.main?.visibleFrame.size

    var body: some Scene {
        WindowGroup {
            Group {
                GeometryReader { geometry in
                    Group {
                        if let users, let currentUser = users.currentUser {
                            ProjectsView(viewModel: ProjectsViewModel(user: currentUser))
                                .environment(discardPopup)
                        } else {
                            WelcomeView(viewModel: welcomeViewModel)
                                .onChange(of: welcomeViewModel.users) { oldValue, newValue in
                                    AppDelegate.users = newValue
                                    users = newValue
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
                backgroundStyle: .dimmed,
                isDestructive: true
            ) {
                VStack {
                    Text(discardPopup.title)
                        .padding()
                    HStack {
                        AnyView.buttonWith(title: "Cancel") {
                            discardPopup.onCancel?()
                            discardPopup.isPresented = false
                        }
                        AnyView.buttonWith(title: "Discard") {
                            discardPopup.onConfirm?()
                            discardPopup.isPresented = false
                        }
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
