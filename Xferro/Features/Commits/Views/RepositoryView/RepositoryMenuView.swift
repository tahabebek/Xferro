//
//  RepositoryViewMenu.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct RepositoryMenuView: View {
    @Binding var isCollapsed: Bool
    @State var showButtons = false

    let deleteRepositoryTapped: () -> Void
    let onFetchTapped: (RepositoryInfo.FetchType) async throws -> Void
    let gitDir: URL
    let head: Head

    var body: some View {
        HStack {
            Image(systemName: "folder")
            Label(gitDir.deletingLastPathComponent().lastPathComponent,
                systemImage: "arrowtriangle.down.fill")
                .foregroundStyle(Color.white)
                .labelStyle(RightImageLabelStyle())
                .fixedSize()
                .contentShape(Rectangle())
                .onTapGesture {
                    showButtons.toggle()
                }
                .popover(isPresented: $showButtons) {
                    VStack(spacing: 0) {
                        XFerroButton<Void>(
                            title: "Fetch",
                            onTap: {
                                fatalError(.unimplemented)
                            }
                        )
                        .padding()
                        XFerroButton<Void>(
                            title: "Fetch all remotes (origin, upstream, etc.)",
                            onTap: {
                                Task {
                                    try await onFetchTapped(.all)
                                }
                            }
                        )
                        .padding()
                        XFerroButton<Void>(
                            title: "Pull \(head.name)",
                            onTap: {
                                fatalError(.unimplemented)
                            }
                        )
                        .padding()
                    }
                }
            Spacer()
            RepositoryNavigationView(isCollapsed: $isCollapsed, deleteRepositoryTapped: deleteRepositoryTapped)
        }
    }
}

/*
 Image(systemName: "arrow.down")
 .contentShape(Rectangle())
 .hoverableButton("Pull changes from remote") {}
 Image(systemName: "arrow.up")
 .contentShape(Rectangle())
 .hoverableButton("Push changes to remote") {}
 Image(systemName: "cursorarrow.click.2")
 .contentShape(Rectangle())
 .hoverableButton("Checkout to a remote branch") {}
 }
 */
