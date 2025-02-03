//
//  main.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import Cocoa
import SwiftUI

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
    @State var users: Users? = DataManager.load(Users.self, filename: Constants.usersFileName)
    private let screenDimensions = NSScreen.main?.visibleFrame.size

    var body: some Scene {
        WindowGroup {
            Group {
                GeometryReader { geometry in
                    Group {
                        if let users, let currentUser = users.currentUser {
                            ProjectsView(viewModel: ProjectsViewModel(user: currentUser))
                        } else {
                            WelcomeView(viewModel: welcomeViewModel)
                                .onChange(of: welcomeViewModel.users) { oldValue, newValue in
                                    AppDelegate.users = newValue
                                    users = newValue
                                }
                        }
                    }
                    .environment(\.windowInfo, geometry.size)
                }
            }
            .border(.gray, width: 1)
            .frame(idealWidth: Dimensions.appWidth, idealHeight: Dimensions.appHeight)
            .task {
                AppDelegate.users = users
            }
        }
    }
}

#endif
