//
//  DetachedTagBranchViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 3/4/25.
//

import Foundation
import Observation

struct DetachedTagBranchViewModel {
    let tagInfo: TagInfo
    let branchCount: Int
    let selectableStatus: SelectableStatus

    let onUserTapped: (any SelectableItem) -> Void
    let onIsSelected: (any SelectableItem) -> Bool
    let onDeleteBranchTapped: (String) -> Void
    let onIsCurrentBranch: (Branch, Head) -> Bool
    let onTapPush: (String, Remote?, Repository.PushType) -> Void
    let onGetLastSelectedRemoteIndex: (String) -> Int
    let onSetLastSelectedRemoteIndex: (Int, String) -> Void
    let onAddRemoteTapped: () -> Void
}
