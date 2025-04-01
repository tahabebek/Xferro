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
        case merge(target: String?, destination: String?)
        case rebase(target: String?, destination: String?)
    }

    @Environment(\.dismiss) var dismiss
    @State var isRemote: Bool = false
    @State var localBranches: [String] = []
    @State var remoteBranches: [String] = []
    @State var selectedRemoteName: String = ""
    @State var selectedLocalBranchName: String = ""
    @State var selectedRemoteBranchName: String = ""
    @State var mergeOrRebaseSourceBranch: String = ""
    @State var mergeOrRebaseTargetBranch: String = ""

    let title: String
    let confirmButtonTitle: String
    let onCheckoutOrDelete: (String, Bool, OperationType) -> Void
    let onMergeOrRebase: (String, String, OperationType) -> Void
    let currentBranch: String
    let operation: OperationType

    init(
        localBranches: [String],
        remoteBranches: [String],
        onCheckoutOrDelete: @escaping (String, Bool, OperationType) -> Void,
        onMergeOrRebase: @escaping (String, String, OperationType) -> Void,
        currentBranch: String,
        operation: OperationType
    ) {
        self.localBranches = localBranches
        self.remoteBranches = remoteBranches
        self.onCheckoutOrDelete = onCheckoutOrDelete
        self.onMergeOrRebase = onMergeOrRebase
        self.currentBranch = currentBranch
        self.operation = operation

        switch operation {
        case .checkout:
            self.title = "Checkout to a Branch"
            self.confirmButtonTitle = "Checkout"
        case .delete:
            self.title = "Delete a Branch"
            self.confirmButtonTitle = "Delete"
        case .merge(let source, let target):
            self.title = "Merge Branches"
            self.confirmButtonTitle = "Merge"
            if let source {
                self._mergeOrRebaseSourceBranch = State(initialValue: source)
            }
            if let target {
                self._mergeOrRebaseTargetBranch = State(initialValue: target)
            }
        case .rebase(let source, let target):
            self.title = "Rebase Branches"
            self.confirmButtonTitle = "Rebase"
            if let source {
                self._mergeOrRebaseSourceBranch = State(initialValue: source)
            }
            if let target {
                self._mergeOrRebaseTargetBranch = State(initialValue: target)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            titleView
            switch operation {
            case .checkout, .delete:
                CheckoutOrDeleteBranchView(
                    isRemote: $isRemote,
                    selectedLocalBranchName: $selectedLocalBranchName,
                    selectedRemoteBranchName: $selectedRemoteBranchName,
                    localBranches: localBranches,
                    remoteBranches: remoteBranches,
                    currentBranch: currentBranch
                )
            case .merge, .rebase:
                MergeOrRebaseBranchView(
                    mergeOrRebaseSourceBranch: $mergeOrRebaseSourceBranch,
                    mergeOrRebaseTargetBranch: $mergeOrRebaseTargetBranch,
                    localBranches: localBranches
                )
            }
            HStack {
                Spacer()
                XFButton<Void,Text>(
                    title: "Cancel",
                    isProminent: false,
                    onTap: {
                        dismiss()
                    }
                )
                XFButton<Void,Text>(
                    title: confirmButtonTitle,
                    onTap: {
                        switch operation {
                        case .checkout, .delete:
                            onCheckoutOrDelete(
                                isRemote ? selectedRemoteBranchName : selectedLocalBranchName,
                                isRemote,
                                operation
                            )
                        case .merge, .rebase:
                            onMergeOrRebase(
                                mergeOrRebaseSourceBranch,
                                mergeOrRebaseTargetBranch,
                                operation
                            )
                        }
                        dismiss()
                    }
                )
            }
            .padding(.bottom)
        }
    }

    var titleView: some View {
        Text(title)
            .font(.formHeading)
            .padding(.horizontal)
            .padding(.bottom)
            .padding(.top, 8)
    }
}

