//
//  DetachedCommitBranchViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 3/4/25.
//

import Foundation

struct DetachedCommitBranchViewModel {
    let detachedCommitInfo: DetachedCommitInfo
    let selectableStatus: SelectableStatus
    let branchCount: Int
    let localBranches: [String]
    let remoteBranches: [String]
    let currentBranch: String

    let onUserTapped: (any SelectableItem) -> Void
    let onIsSelected: (any SelectableItem) -> Bool
    let onDeleteBranchTapped: (String) -> Void
    let onIsCurrentBranch: (Branch, Head) -> Bool
    let onTapPush: (String, Remote?, Repository.PushType) -> Void
    let onGetLastSelectedRemoteIndex: (String) -> Int
    let onSetLastSelectedRemoteIndex: (Int, String) -> Void
    let onAddRemoteTapped: () -> Void
    let onCreateBranchTapped: (String, String, Bool, Bool) -> Void
    let onCheckoutOrDelete: (String, Bool, BranchOperationView.OperationType) -> Void
    let onMergeOrRebase: (String, String, BranchOperationView.OperationType) -> Void
}
