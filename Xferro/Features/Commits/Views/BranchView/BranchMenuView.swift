//
//  BranchMenuView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct BranchMenuView: View {
    @Binding var showingBranchOptions: Bool
    let isCurrent: Bool
    let name: String
    let isDetached: Bool
    let onDeleteBranchTapped: ((String) -> Void)?
    let onPushBranchToRemoteTapped: ((String)-> Void)?
    let branchCount: Int

    var body: some View {
        Button(action: {
            showingBranchOptions = true
        }) {
            Label(name, systemImage: Images.actionButtonSystemImageName)
                .foregroundStyle(isCurrent ? Color.accentColor : Color.white)
                .fixedSize()
                .labelStyle(RightImageLabelStyle())
        }
        .buttonStyle(PlainButtonStyle())
        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        .background(Color.clear)
        .frame(minWidth: 40)
        .popover(isPresented: $showingBranchOptions) {
            VStack(alignment: .leading, spacing: 8) {
                if !isCurrent {
                    XFerroButton<Void>(
                        title: "Switch to \(name)",
                        onTap: {
                            showingBranchOptions = false
                            fatalError(.unimplemented)
                        }
                    )
                    if !isDetached {
                        XFerroButton<Void>(
                            title: "Delete \(name)",
                            onTap: {
                                showingBranchOptions = false
                                onDeleteBranchTapped?(name)
                            }
                        )
                    }
                }

                XFerroButton<Void>(
                    title: "Push to remote",
                    onTap: {
                        showingBranchOptions = false
                        onPushBranchToRemoteTapped?(name)
                    }
                )
                XFerroButton<Void>(
                    title: "Create a new branch based on \(name)",
                    onTap: {
                        showingBranchOptions = false
                        fatalError(.unimplemented)
                    }
                )

                if !isDetached, branchCount > 1 {
                    Divider()
                    XFerroButton<Void>(
                        title: "Merge a branch into \(name)",
                        onTap: {
                            showingBranchOptions = false
                            fatalError(.unimplemented)
                        }
                    )
                    XFerroButton<Void>(
                        title: "Merge \(name) into another branch",
                        onTap: {
                            showingBranchOptions = false
                            fatalError(.unimplemented)
                        }
                    )
                    Divider()
                    XFerroButton<Void>(
                        title: "Rebase a branch into \(name)",
                        onTap: {
                            showingBranchOptions = false
                            fatalError(.unimplemented)
                        }
                    )
                    XFerroButton<Void>(
                        title: "Rebase \(name) into another branch",
                        onTap: {
                            showingBranchOptions = false
                            fatalError(.unimplemented)
                        }
                    )
                }
            }
            .padding()
            .frame(minWidth: 250)
        }
    }
}
