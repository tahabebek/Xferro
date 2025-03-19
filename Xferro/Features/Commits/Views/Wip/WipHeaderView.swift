//
//  WipHeaderView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct WipHeaderView: View {
    @Binding var autoCommitEnabled: Bool
    @State var showButtons = false
    let onAddManualWipCommitTapped: () -> Void
    let onDeleteWipWorktreeTapped: () -> Void
    let tooltipForDeleteRepo: String
    let tooltipForDeleteBranch: String?
    let isNotEmpty: Bool

    var body: some View {
        HStack {
            Button(action: {
                showButtons = true
            }) {
                Label {
                    Text("Work in Progress")
                        .font(.title2)
                } icon: {
                    Image(systemName: "arrowtriangle.down.fill")
                }
                .fixedSize()
                .labelStyle(RightImageLabelStyle())
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.leading, 6)
            Spacer()
            XFerroButton<Void>(
                title: "Commit",
                onTap: {
                    onAddManualWipCommitTapped()
                }
            )
            .padding(.trailing, 4)
            .opacity(!autoCommitEnabled ? 0 : 1)
        }
        .popover(isPresented: $showButtons) {
            VStack(alignment: .leading, spacing: 8) {
                XFerroButton<Void>(
                    title: tooltipForDeleteBranch ?? "",
                    onTap: {
                        showButtons = false
                    }
                )
                .padding(.vertical, tooltipForDeleteBranch != nil ? 4 : 0)
                .opacity(tooltipForDeleteBranch != nil ? 1 : 0)

                XFerroButton<Void>(
                    title: tooltipForDeleteRepo,
                    onTap: {
                        showButtons = false
                    }
                )
                .padding(.vertical, 4)
                Divider()
                XFerroButton<Void>(
                    title: "Wip Settings",
                    isProminent: false,
                    onTap: {
                        showButtons = false
                    }
                )
                .padding(.vertical, 4)
            }
            .padding()
            .frame(minWidth: 250)
        }
        .animation(.default, value: autoCommitEnabled)
    }
}
