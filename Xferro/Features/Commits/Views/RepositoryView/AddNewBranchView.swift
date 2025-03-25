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
    @State var selectedLocalBranchName: String = ""
    @State var selectedRemoteBranchName: String = ""

    let localBranches: [String]
    let remoteBranches: [String]
    let onCreateBranch: (String, String, Bool, Bool) -> Void
    let currentBranch: String?
    let preselectedLocalBranch: String?

    init(
        localBranches: [String] = [],
        remoteBranches: [String] = [],
        onCreateBranch: @escaping (String, String, Bool, Bool) -> Void,
        currentBranch: String? = nil,
        preselectedLocalBranch: String? = nil
    ) {
        self.localBranches = localBranches
        self.remoteBranches = remoteBranches
        self.onCreateBranch = onCreateBranch
        self.currentBranch = currentBranch
        self.preselectedLocalBranch = preselectedLocalBranch
        if let currentBranch {
            isRemote = false
            selectedLocalBranchName = currentBranch
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            titleView
            Group {
                if preselectedLocalBranch == nil {
                    settingsView
                    invalidMessageView
                } else {
                    preselectedSettingsView
                }
            }
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
                        if let preselectedLocalBranch {
                            selectedLocalBranchName = preselectedLocalBranch
                        } else {
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

    var preselectedSettingsView: some View {
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
                Text("Checkout:")
                Toggle("", isOn: $shouldCheckout)
                Spacer()
            }
        }
        .padding(.leading, 8)
        .font(.formField)
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
        Text(
            preselectedLocalBranch != nil ? "Create a New Branch Based on \(preselectedLocalBranch!)"
            : "Create a New Branch"
        )
        .font(.formHeading)
        .padding(.horizontal)
        .padding(.bottom)
        .padding(.top, 8)
    }
}
