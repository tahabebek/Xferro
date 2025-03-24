//
//  CheckoutBranchView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/24/25.
//

import SwiftUI

struct CheckoutBranchView: View {
    @Environment(\.dismiss) var dismiss
    @State var isRemote: Bool = false
    @State var localBranches: [String] = []
    @State var remoteBranches: [String] = []
    @State var selectedRemoteName: String = ""
    @State var selectedLocalBranchName: String = ""
    @State var selectedRemoteBranchName: String = ""

    let onCheckoutBranch: (String, Bool) -> Void
    let currentBranch: String

    var body: some View {
        VStack(alignment: .leading) {
            titleView
            settingsView
            HStack {
                Spacer()
                XFButton<Void>(
                    title: "Cancel",
                    isProminent: false,
                    onTap: {
                        dismiss()
                    }
                )
                XFButton<Void>(
                    title: "Checkout",
                    onTap: {
                        onCheckoutBranch(
                            isRemote ? selectedRemoteBranchName : selectedLocalBranchName,
                            isRemote
                        )
                        dismiss()
                    }
                )
            }
            .padding(.bottom)
        }
        .onAppear {
            selectedLocalBranchName = currentBranch
            selectedRemoteBranchName = remoteBranches.first ?? ""
        }
    }

    var settingsView: some View {
        VStack(alignment: .leading) {
            Picker("", selection: $isRemote) {
                Text("Local branch").tag(false)
                Text("Remote branch").tag(true)
            }
            .pickerStyle(.menu)
            .padding(.bottom)
            Group {
                if !isRemote {
                    localSettingsView
                }
                else {
                    remoteSettingsView
                }
            }
        }
        .font(.formField)
    }

    var remoteSettingsView: some View {
        SearchablePickerView(
            items: remoteBranches,
            selectedItem: $selectedRemoteBranchName,
            title: "Select Branch:"
        )
        .padding(.leading, 8)
        .padding(.bottom)
    }

    var localSettingsView: some View {
        SearchablePickerView(
            items: localBranches,
            selectedItem: $selectedLocalBranchName,
            title: "Select Branch:"
        )
        .padding(.leading, 8)
        .padding(.bottom)
    }

    var titleView: some View {
        Text("Checkout to a Branch")
            .font(.formHeading)
            .padding(.horizontal)
            .padding(.bottom)
            .padding(.top, 8)
    }
}

