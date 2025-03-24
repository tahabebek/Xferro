//
//  AddNewBranchView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/24/25.
//

import SwiftUI

struct AddNewBranchView: View {
    @Environment(\.dismiss) var dismiss
    @FocusState var isTextFieldFocused: Bool
    @State var name: String = ""
    @State var isRemote: Bool = false
    @State var shouldCheckout: Bool = false
    @State var invalidMessage: String?
    @State var localBranches: [String] = []
    @State var remoteBranches: [String] = []
    @State var selectedRemoteName: String = ""
    @State var selectedLocalBranchName: String = ""
    @State var selectedRemoteBranchName: String = ""

    let onCreateBranch: (String, String, Bool, Bool) -> Void
    let currentBranch: String

    var body: some View {
        VStack(alignment: .leading) {
            titleView
            settingsView
            invalidMessageView
                .padding(.bottom)
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
                    title: "Create Branch",
                    onTap: {
                        if isRemote {
                            if selectedRemoteBranchName.isEmptyOrWhitespace {
                                invalidMessage = "Please select a remote branch"
                                return
                            }
                        } else {
                            if selectedLocalBranchName.isEmptyOrWhitespace {
                                invalidMessage = "Please select a local branch"
                                return
                            }
                        }
                        if name.isEmpty {
                            invalidMessage = "Please enter a name"
                            return
                        }
                        onCreateBranch(
                            name,
                            isRemote ? selectedRemoteBranchName : selectedLocalBranchName,
                            isRemote,
                            shouldCheckout
                        )
                        dismiss()
                    }
                )
            }
            .padding(.bottom)
        }
        .animation(.default, value: invalidMessage)
        .textFieldStyle(.roundedBorder)
        .onAppear {
            selectedLocalBranchName = currentBranch
            selectedRemoteBranchName = remoteBranches.first ?? ""
            isTextFieldFocused = true
        }
    }

    var invalidMessageView: some View {
        HStack {
            Spacer()
            Text(invalidMessage ?? "")
                .font(.validationError)
                .foregroundStyle(.red)
                .opacity(invalidMessage == nil ? 0 : 1)
            Spacer()
        }
    }

    var settingsView: some View {
        VStack(alignment: .leading) {
            Picker("", selection: $isRemote) {
                Text("Based on a local branch").tag(false)
                Text("Based on a remote branch for tracking").tag(true)
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
        VStack(alignment: .leading) {
            HStack {
                Text("Name:")
                Spacer()
                TextField(
                    "Name",
                    text: $name,
                    axis: .vertical
                )
                .focused($isTextFieldFocused)
            }
            HStack {
                SearchablePickerView(
                    items: remoteBranches,
                    selectedItem: $selectedRemoteBranchName,
                    title: "Based on:"
                )
                .padding(.vertical)
            }
            HStack {
                Text("Checkout:")
                Toggle("", isOn: $shouldCheckout)
                Spacer()
            }
        }
        .padding(.leading, 8)
    }

    var localSettingsView: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Name:")
                Spacer()
                TextField(
                    "Name",
                    text: $name,
                    axis: .vertical
                )
                .focused($isTextFieldFocused)
            }
            HStack {
                SearchablePickerView(
                    items: localBranches,
                    selectedItem: $selectedLocalBranchName,
                    title: "Based on:"
                )
            }
            .padding(.vertical)
            HStack {
                Text("Checkout:")
                Toggle("", isOn: $shouldCheckout)
                Spacer()
            }
        }
        .padding(.leading, 8)
    }

    var titleView: some View {
        Text("Create New Branch")
            .font(.formHeading)
            .padding(.horizontal)
            .padding(.bottom)
            .padding(.top, 8)
    }
}
