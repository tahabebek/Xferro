//
//  BranchViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 3/2/25.
//

import Foundation

struct BranchViewModel {
    let onUserTapped: ((any SelectableItem) -> Void)?
    let onIsSelected: ((any SelectableItem) -> Bool)?
    let onDeleteBranchTapped: ((String) -> Void)?
    let onIsCurrentBranch: ((Branch, Head) -> Bool)?
    let onPushBranchToRemoteTapped: ((String) -> Void)?
    let branchInfo: BranchInfo
    let selectableStatus: SelectableStatus
    let isCurrent: Bool
    let branchCount: Int

    init(
        onUserTapped: ((any SelectableItem) -> Void)?,
        onIsSelected: ((any SelectableItem) -> Bool)?,
        onDeleteBranchTapped: ((String) -> Void)?,
        onIsCurrentBranch: ((Branch, Head) -> Bool)?,
        onPushBranchToRemoteTapped: ((String) -> Void)?,
        branchInfo: BranchInfo,
        isCurrent: Bool,
        branchCount: Int,
        selectableStatus: SelectableStatus
    )
    {
        self.onUserTapped = onUserTapped
        self.onIsSelected = onIsSelected
        self.onDeleteBranchTapped = onDeleteBranchTapped
        self.onIsCurrentBranch = onIsCurrentBranch
        self.onPushBranchToRemoteTapped = onPushBranchToRemoteTapped
        self.branchInfo = branchInfo
        self.isCurrent = isCurrent
        self.branchCount = branchCount
        self.selectableStatus = selectableStatus
    }
}
