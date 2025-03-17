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
            Label(name, systemImage: "arrowtriangle.down.fill")
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
                    Button("Switch to \(name)") {
                        print("Switch to branch")
                        showingBranchOptions = false
                    }
                    .padding(.vertical, 4)

                    if !isDetached {
                        Button("Delete \(name)") {
                            onDeleteBranchTapped?(name)
                            showingBranchOptions = false
                        }
                        .padding(.vertical, 4)
                    }
                }

                Button("Push to remote") {
                    showingBranchOptions = false
                    onPushBranchToRemoteTapped?(name)
                }
                .padding(.vertical, 4)

                Button("Create a new branch based on \(name)") {
                    print("Create branch")
                    showingBranchOptions = false
                }
                .padding(.vertical, 4)

                if !isDetached, branchCount > 1 {
                    Divider()

                    Button("Merge a branch into \(name)") {
                        print("Merge into")
                        showingBranchOptions = false
                    }
                    .padding(.vertical, 4)

                    Button("Rebase a branch into \(name)") {
                        print("Rebase into")
                        showingBranchOptions = false
                    }
                    .padding(.vertical, 4)

                    Button("Merge \(name) into another branch") {
                        print("Merge to")
                        showingBranchOptions = false
                    }
                    .padding(.vertical, 4)

                    Button("Rebase \(name) into another branch") {
                        print("Rebase to")
                        showingBranchOptions = false
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .frame(minWidth: 250)
        }
    }
}
