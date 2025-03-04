//
//  DetachedCommitBranchViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 3/4/25.
//

import Foundation

struct DetachedCommitBranchViewModel {
    let onUserTapped: ((any SelectableItem) -> Void)?
    let onIsSelected: ((any SelectableItem) -> Bool)?
    let onDeleteBranchTapped: ((String) -> Void)?
    let onIsCurrentBranch: ((Branch, Head) -> Bool)?
    let detachedCommitInfo: DetachedCommitInfo
    let selectableStatus: SelectableStatus
    let branchCount: Int
    
    init(
        onUserTapped: ((any SelectableItem) -> Void)?,
        onIsSelected: ((any SelectableItem) -> Bool)?,
        onDeleteBranchTapped: ((String) -> Void)?,
        onIsCurrentBranch: ((Branch, Head) -> Bool)?,
        detachedCommitInfo: DetachedCommitInfo,
        branchCount: Int,
        selectableStatus: SelectableStatus
    )
    {
        self.onUserTapped = onUserTapped
        self.onIsSelected = onIsSelected
        self.onDeleteBranchTapped = onDeleteBranchTapped
        self.onIsCurrentBranch = onIsCurrentBranch
        self.detachedCommitInfo = detachedCommitInfo
        self.branchCount = branchCount
        self.selectableStatus = selectableStatus
    }
}
