//
//  main.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import Cocoa
import StoreKit
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
    @State var showPaywall: Bool = false
    @State var frame: CGRect = .zero
    private let screenDimensions = NSScreen.main?.visibleFrame

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
            .background(Color.fabulaBack2)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    HStack(spacing: 6) {
                        if let activity = ProgressManager.shared.activity {
                            ProgressView()
                                .controlSize(.small)
                            Text(activity.name)
                                .font(.paragraph3)
                        }
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
            }
            .frame(minWidth: 800, minHeight: 600)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(idealWidth: frame.width, idealHeight: frame.height)
            .task {
                AppDelegate.users = users
            }
            .preferredColorScheme(.dark)
            .onAppear {
                frame = screenDimensions ?? .zero
                showPaywall = true
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
}

#endif
