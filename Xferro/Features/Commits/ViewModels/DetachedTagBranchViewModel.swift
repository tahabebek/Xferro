//
//  DetachedTagBranchViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 3/4/25.
//

import Foundation
import Observation

@Observable final class DetachedTagBranchViewModel {
    let onUserTapped: ((any SelectableItem) -> Void)?
    let onIsSelected: ((any SelectableItem) -> Bool)?
    let onDeleteBranchTapped: ((String) -> Void)?
    let onIsCurrentBranch: ((Branch, Head) -> Bool)?
    let tagInfo: TagInfo
    let branchCount: Int
    let selectableStatus: SelectableStatus

    init(
        onUserTapped: ((any SelectableItem) -> Void)?,
        onIsSelected: ((any SelectableItem) -> Bool)?,
        onDeleteBranchTapped: ((String) -> Void)?,
        onIsCurrentBranch: ((Branch, Head) -> Bool)?,
        tagInfo: TagInfo,
        branchCount: Int,
        selectableStatus: SelectableStatus
    )
    {
        self.onUserTapped = onUserTapped
        self.onIsSelected = onIsSelected
        self.onDeleteBranchTapped = onDeleteBranchTapped
        self.onIsCurrentBranch = onIsCurrentBranch
        self.tagInfo = tagInfo
        self.branchCount = branchCount
        self.selectableStatus = selectableStatus
    }
}
