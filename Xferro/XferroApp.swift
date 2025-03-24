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
    @State private var projectsViewModel: ProjectsViewModel? = ProjectsViewModel(user: DataManager.load(Users.self, filename: DataManager.usersFileName)?.currentUser)
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
            //            .frame(idealWidth: Dimensions.appWidth, idealHeight: Dimensions.appHeight)
            .background(Color.fabulaBack2)
            .toolbar {
                ToolbarItem(placement: .status) {
                    HStack(spacing: 6) {
                        if ProgressManager.shared.isActive {
                            ProgressView()
                                .controlSize(.small)
                            Text(ProgressManager.shared.currentActivityName)
                                .font(.body)
                        }
                        Images.infoButtonImage
                            .frame(width: 16, height: 16)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                openURL(URL(string: "https://xferro.ai")!)
                            }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            .preferredColorScheme(.dark)
        }
    }
}

#endif
