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
    private let screenDimensions = NSScreen.main?.visibleFrame.size
    @State var users: Users? = DataManager.load(Users.self, filename: Constants.usersFileName)

    var body: some Scene {
        WindowGroup {
            Group {
                GeometryReader { geometry in
                    Group {
                        if let users {
                            Text("We have user \(users.currentUser!.commitIdentity.name)")
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
            .frame(width: Dimensions.appWidth, height: Dimensions.appHeight)
        }
    }
}

#endif
