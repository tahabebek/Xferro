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
    @Environment(\.openURL) private var openURL
    
    @State private var welcomeViewModel = WelcomeViewModel()
    @State private var users: Users? = DataManager.load(Users.self, filename: DataManager.usersFileName)
    @State private var projectsViewModel: ProjectsViewModel?
    @State private var statusViewModel = StatusViewModel()

    private let screenDimensions = NSScreen.main?.visibleFrame.size

    var body: some Scene {
        WindowGroup {
            Group {
                GeometryReader { geometry in
                    Group {
                        if let projectsViewModel {
                            ProjectsView(viewModel: projectsViewModel, statusViewModel: statusViewModel)
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
            .font(.heading0)
            //            .frame(idealWidth: Dimensions.appWidth, idealHeight: Dimensions.appHeight)
            .background(Color.fabulaBack2)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    HStack(spacing: 6) {
                        Images.settingsButtonImage
                            .font(.paragraph3)
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                AppDelegate.showSettings()
                            }
                        Images.infoButtonImage
                            .font(.paragraph3)
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                openURL(URL(string: "https://xferro.ai")!)
                            }
                    }
                }
                ToolbarItem(placement: .principal) {
                    if let activity = ProgressManager.shared.activity {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text(activity.name)
                                .font(.paragraph3)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .task {
                AppDelegate.users = users
                if projectsViewModel == nil {
                    projectsViewModel = ProjectsViewModel(user: users?.currentUser!)
                }
                do {
                    try Tips.configure()
                }
                catch {
                    // Handle TipKit errors
                    print("Error initializing TipKit \(error.localizedDescription)")
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

#endif
