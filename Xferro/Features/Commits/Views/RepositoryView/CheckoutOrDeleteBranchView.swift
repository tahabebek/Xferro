//
//  CheckoutOrDeleteBranchView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/25/25.
//

import SwiftUI

struct CheckoutOrDeleteBranchView: View {
    @Binding var isRemote: Bool
    @Binding var selectedLocalBranchName: String
    @Binding var selectedRemoteBranchName: String
    
    let localBranches: [String]
    let remoteBranches: [String]
    let currentBranch: String

    var body: some View {
        settingsView
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
}
