//
//  BranchOperationView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/24/25.
//

import SwiftUI

struct BranchOperationView: View {
    enum OperationType {
        case checkout
        case delete
        case merge
        case rebase
    }

    @Environment(\.dismiss) var dismiss
    @State var isRemote: Bool = false
    @State var localBranches: [String] = []
    @State var remoteBranches: [String] = []
    @State var selectedRemoteName: String = ""
    @State var selectedLocalBranchName: String = ""
    @State var selectedRemoteBranchName: String = ""

    let title: String
    let confirmButtonTitle: String
    let onConfirm: (String, Bool, OperationType) -> Void
    let currentBranch: String
    let operation: OperationType

    init(
        localBranches: [String],
        remoteBranches: [String],
        onConfirm: @escaping (String, Bool, OperationType) -> Void,
        currentBranch: String,
        operation: OperationType
    ) {
        self.localBranches = localBranches
        self.remoteBranches = remoteBranches
        self.onConfirm = onConfirm
        self.currentBranch = currentBranch
        self.operation = operation

        self.title = switch operation {
            case .checkout:
                "Checkout to a Branch"
            case .delete:
                "Delete a Branch"
            case .merge:
                "Merge a Branch"
            case .rebase:
                "Rebase a Branch"
        }

        self.confirmButtonTitle = switch operation {
            case .checkout:
                "Checkout"
            case .delete:
                "Delete"
            case .merge:
                "Merge"
            case .rebase:
                "Rebase"
        }
    }

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
                    title: confirmButtonTitle,
                    onTap: {
                        onConfirm(
                            isRemote ? selectedRemoteBranchName : selectedLocalBranchName,
                            isRemote,
                            operation
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
        Text(title)
            .font(.formHeading)
            .padding(.horizontal)
            .padding(.bottom)
            .padding(.top, 8)
    }
}

